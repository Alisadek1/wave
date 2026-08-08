<?php

declare(strict_types=1);

class ShiftController
{
    // ── List ──────────────────────────────────────────────────
    public function index(array $params): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.view');

        $db      = Database::getInstance();
        $page    = max(1, (int)($_GET['page'] ?? 1));
        $perPage = min(100, max(10, (int)($_GET['per_page'] ?? 20)));
        $status  = trim($_GET['status'] ?? '');
        $userId  = (int)($_GET['user_id'] ?? 0);
        $from    = trim($_GET['date_from'] ?? '');
        $to      = trim($_GET['date_to']   ?? '');

        $where = ['1=1'];
        $binds = [];

        if ($status !== '') {
            $where[] = 's.status = ?';
            $binds[] = $status;
        }
        if ($userId > 0) {
            $where[] = 's.user_id = ?';
            $binds[] = $userId;
        }
        if ($from !== '') {
            $where[] = 'DATE(s.opened_at) >= ?';
            $binds[] = $from;
        }
        if ($to !== '') {
            $where[] = 'DATE(s.opened_at) <= ?';
            $binds[] = $to;
        }

        $whereStr = implode(' AND ', $where);
        $total    = $db->prepare("SELECT COUNT(*) FROM shifts s WHERE {$whereStr}");
        $total->execute($binds);
        $total = (int)$total->fetchColumn();

        $offset = ($page - 1) * $perPage;
        $stmt   = $db->prepare("
            SELECT s.*, u.name AS opened_by_name, ub.name AS closed_by_name
            FROM shifts s
            LEFT JOIN users u  ON u.id = s.user_id
            LEFT JOIN users ub ON ub.id = s.closed_by
            WHERE {$whereStr}
            ORDER BY s.opened_at DESC
            LIMIT ? OFFSET ?
        ");
        $stmt->execute([...$binds, $perPage, $offset]);

        Response::paginated($stmt->fetchAll(), $total, $page, $perPage);
    }

    // ── Current open shift for the authenticated cashier ──────
    public function current(array $params): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.view');

        $db   = Database::getInstance();
        $stmt = $db->prepare("
            SELECT s.*, u.name AS opened_by_name
            FROM shifts s
            LEFT JOIN users u ON u.id = s.user_id
            WHERE s.user_id = ? AND s.status = 'open'
            ORDER BY s.id DESC LIMIT 1
        ");
        $stmt->execute([$user['id']]);
        $shift = $stmt->fetch();

        if ($shift) {
            $calc = CashCalculationService::calculate((int)$shift['id'], $db);
            foreach ($calc as $k => $v) {
                $shift["live_{$k}"] = $v;
            }
            // Also fetch recent cash movements
            $movStmt = $db->prepare("
                SELECT m.*, u.name AS created_by_name
                FROM shift_cash_movements m
                LEFT JOIN users u ON u.id = m.created_by
                WHERE m.shift_id = ?
                ORDER BY m.created_at DESC
                LIMIT 20
            ");
            $movStmt->execute([(int)$shift['id']]);
            $shift['cash_movements'] = $movStmt->fetchAll();
        }

        Response::success($shift ?: null);
    }

    // ── Open a new shift ──────────────────────────────────────
    public function open(array $params): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.view');

        $body = $_POST;
        $db   = Database::getInstance();

        $existing = $db->prepare("SELECT id FROM shifts WHERE user_id = ? AND status = 'open'");
        $existing->execute([$user['id']]);
        if ($existing->fetch()) {
            Response::error('You already have an open shift', 409);
        }

        $stmt = $db->prepare("
            INSERT INTO shifts (user_id, opening_cash, notes, status)
            VALUES (?, ?, ?, 'open')
        ");
        $stmt->execute([
            $user['id'],
            (float)($body['opening_cash'] ?? 0),
            trim($body['notes'] ?? ''),
        ]);

        $id    = (int)$db->lastInsertId();
        $shift = $this->getById($db, $id);

        Logger::activity($user['id'], 'create', 'shifts', $id, "Opened shift #{$id}");
        Response::created($shift, 'Shift opened successfully');
    }

    // ── Close a shift ─────────────────────────────────────────
    public function close(array $params): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.view');

        $id   = (int)$params['id'];
        $body = $_POST;
        $db   = Database::getInstance();

        $shift = $this->getById($db, $id);
        if (!$shift) {
            Response::notFound('Shift not found');
        }
        if ($shift['status'] === 'closed') {
            Response::error('Shift is already closed', 409);
        }
        if ((int)$shift['user_id'] !== (int)$user['id']) {
            AuthMiddleware::require($user, 'shifts.manage');
        }

        // Use CashCalculationService for the authoritative calculation
        $calc = CashCalculationService::calculate($id, $db);

        $countedCash = (float)($body['counted_cash'] ?? $body['closing_cash'] ?? 0);
        $difference  = round($countedCash - $calc['expected_cash'], 3);
        $status      = CashCalculationService::balanceStatus($difference);

        $db->prepare("
            UPDATE shifts SET
                closing_cash    = ?,
                counted_cash    = ?,
                expected_cash   = ?,
                difference      = ?,
                balance_status  = ?,
                cash_sales      = ?,
                card_sales      = ?,
                wallet_sales    = ?,
                cash_refunds    = ?,
                refunds_total   = ?,
                cash_in_total   = ?,
                cash_out_total  = ?,
                expenses_total  = ?,
                sales_total     = ?,
                notes           = ?,
                status          = 'closed',
                closed_at       = NOW(),
                closed_by       = ?
            WHERE id = ?
        ")->execute([
            $countedCash,
            $countedCash,
            $calc['expected_cash'],
            $difference,
            $status,
            $calc['cash_sales'],
            $calc['card_sales'],
            $calc['wallet_sales'],
            $calc['cash_refunds'],
            $calc['cash_refunds'],    // refunds_total = cash_refunds (only cash affects drawer)
            $calc['cash_in'],
            $calc['cash_out'],
            $calc['cash_expenses'],
            $calc['total_sales'],
            trim($body['notes'] ?? $shift['notes'] ?? ''),
            $user['id'],
            $id,
        ]);

        $updated = $this->getById($db, $id);
        $updated['cash_breakdown'] = $calc;

        Logger::activity($user['id'], 'update', 'shifts', $id, "Closed shift #{$id} — status: {$status}");
        Response::success($updated, 'Shift closed successfully');
    }

    // ── Show single shift with full detail ────────────────────
    public function show(array $params): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.view');

        $id    = (int)$params['id'];
        $db    = Database::getInstance();
        $shift = $this->getById($db, $id);

        if (!$shift) {
            Response::notFound('Shift not found');
        }

        // Attach live calculation (works for both open and closed)
        $shift['cash_breakdown'] = CashCalculationService::calculate($id, $db);

        $expenses = $db->prepare("
            SELECT e.*, ec.name AS category_name, ec.name_ar AS category_name_ar
            FROM expenses e
            JOIN expense_categories ec ON ec.id = e.category_id
            WHERE e.shift_id = ?
            ORDER BY e.created_at ASC
        ");
        $expenses->execute([$id]);
        $shift['expenses'] = $expenses->fetchAll();

        $sales = $db->prepare("
            SELECT id, invoice_number, total, cash_amount, visa_amount, wallet_amount,
                   payment_method, sale_date, status
            FROM sales WHERE shift_id = ? ORDER BY sale_date ASC
        ");
        $sales->execute([$id]);
        $shift['sales'] = $sales->fetchAll();

        $movements = $db->prepare("
            SELECT m.*, u.name AS created_by_name
            FROM shift_cash_movements m
            LEFT JOIN users u ON u.id = m.created_by
            WHERE m.shift_id = ?
            ORDER BY m.created_at ASC
        ");
        $movements->execute([$id]);
        $shift['cash_movements'] = $movements->fetchAll();

        Response::success($shift);
    }

    // ── Cash In ───────────────────────────────────────────────
    public function cashIn(array $params): void
    {
        $this->recordCashMovement($params, 'cash_in');
    }

    // ── Cash Out ──────────────────────────────────────────────
    public function cashOut(array $params): void
    {
        $this->recordCashMovement($params, 'cash_out');
    }

    // ── Private ───────────────────────────────────────────────
    private function recordCashMovement(array $params, string $type): void
    {
        $user = AuthMiddleware::handle();
        AuthMiddleware::require($user, 'shifts.cash_movement');

        $body   = $_POST;
        $db     = Database::getInstance();
        $amount = (float)($body['amount'] ?? 0);

        if ($amount <= 0) {
            Response::error('Amount must be greater than zero');
        }

        // Resolve shift: use active shift if no shift_id provided
        $shiftId = isset($body['shift_id']) && (int)$body['shift_id'] > 0
            ? (int)$body['shift_id']
            : null;

        if (!$shiftId) {
            $row = $db->prepare("SELECT id FROM shifts WHERE user_id = ? AND status = 'open' LIMIT 1");
            $row->execute([$user['id']]);
            $shiftId = (int)$row->fetchColumn() ?: null;
        }

        if (!$shiftId) {
            Response::error('No open shift found. Open a shift before adding cash movements.', 422);
        }

        // Verify shift is open
        $shiftRow = $db->prepare("SELECT status FROM shifts WHERE id = ?");
        $shiftRow->execute([$shiftId]);
        $shiftStatus = $shiftRow->fetchColumn();
        if ($shiftStatus !== 'open') {
            Response::error('Cannot add cash movement to a closed shift', 409);
        }

        $db->prepare("
            INSERT INTO shift_cash_movements (shift_id, type, amount, reason, created_by)
            VALUES (?, ?, ?, ?, ?)
        ")->execute([
            $shiftId,
            $type,
            round($amount, 3),
            trim($body['reason'] ?? ''),
            $user['id'],
        ]);

        $movId = (int)$db->lastInsertId();
        $label = $type === 'cash_in' ? 'Cash In' : 'Cash Out';
        Logger::activity($user['id'], 'create', 'shifts', $shiftId,
            "{$label}: " . number_format($amount, 3) . ($body['reason'] ? ' — ' . $body['reason'] : ''));

        // Return updated expected cash so the UI can refresh instantly
        $calc = CashCalculationService::calculate($shiftId, $db);

        Response::created([
            'id'           => $movId,
            'shift_id'     => $shiftId,
            'type'         => $type,
            'amount'       => round($amount, 3),
            'reason'       => trim($body['reason'] ?? ''),
            'expected_cash'=> $calc['expected_cash'],
        ], "{$label} recorded successfully");
    }

    private function getById(PDO $db, int $id): ?array
    {
        $stmt = $db->prepare("
            SELECT s.*, u.name AS opened_by_name, ub.name AS closed_by_name
            FROM shifts s
            LEFT JOIN users u  ON u.id = s.user_id
            LEFT JOIN users ub ON ub.id = s.closed_by
            WHERE s.id = ?
        ");
        $stmt->execute([$id]);
        return $stmt->fetch() ?: null;
    }
}
