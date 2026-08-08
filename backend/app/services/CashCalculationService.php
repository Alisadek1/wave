<?php

declare(strict_types=1);

/**
 * Single source of truth for drawer cash balance.
 *
 * Expected Cash = Opening Cash
 *               + Cash Sales        (cash_amount on completed sales)
 *               + Cash In
 *               - Cash Refunds      (refunds pro-rated by original sale's cash portion)
 *               - Cash Expenses     (expenses paid in cash)
 *               - Cash Out
 *
 * Card / Instapay / Vodafone / Bank transactions NEVER affect expected cash.
 */
class CashCalculationService
{
    /**
     * Calculate full cash breakdown for a shift.
     * Works for both open (live) and closed shifts.
     */
    public static function calculate(int $shiftId, PDO $db): array
    {
        // ── Sales breakdown ─────────────────────────────────────
        $salesRow = $db->prepare("
            SELECT
                COALESCE(SUM(cash_amount),   0) AS cash_sales,
                COALESCE(SUM(visa_amount),   0) AS card_sales,
                COALESCE(SUM(wallet_amount), 0) AS wallet_sales,
                COALESCE(SUM(total),         0) AS total_sales,
                COUNT(*)                        AS sales_count
            FROM sales
            WHERE shift_id = ? AND status IN ('completed','partial_refund','refunded')
        ");
        $salesRow->execute([$shiftId]);
        $sales = $salesRow->fetch(PDO::FETCH_ASSOC);

        // wallet_amount covers instapay AND vodafone_cash (split at POS level)
        // We store it all as wallet_sales here; detailed breakdown requires POS changes
        $cashSales   = (float)$sales['cash_sales'];
        $cardSales   = (float)$sales['card_sales'];
        $walletSales = (float)$sales['wallet_sales'];
        $totalSales  = (float)$sales['total_sales'];
        $salesCount  = (int)$sales['sales_count'];

        // ── Cash refunds ────────────────────────────────────────
        // Pro-rate each return by the original sale's cash portion
        $refRow = $db->prepare("
            SELECT COALESCE(
                SUM(r.total_amount * (s.cash_amount / NULLIF(s.total, 0))),
            0) AS cash_refunds
            FROM returns r
            JOIN sales s ON s.id = r.reference_id AND r.type = 'sale'
            WHERE s.shift_id = ? AND r.status = 'completed'
        ");
        $refRow->execute([$shiftId]);
        $cashRefunds = (float)$refRow->fetchColumn();

        // ── Cash expenses ───────────────────────────────────────
        $expRow = $db->prepare("
            SELECT COALESCE(SUM(amount), 0)
            FROM expenses
            WHERE shift_id = ? AND payment_method = 'cash'
        ");
        $expRow->execute([$shiftId]);
        $cashExpenses = (float)$expRow->fetchColumn();

        // ── Cash In / Cash Out ──────────────────────────────────
        $movRow = $db->prepare("
            SELECT
                COALESCE(SUM(CASE WHEN type = 'cash_in'  THEN amount ELSE 0 END), 0) AS cash_in,
                COALESCE(SUM(CASE WHEN type = 'cash_out' THEN amount ELSE 0 END), 0) AS cash_out
            FROM shift_cash_movements
            WHERE shift_id = ?
        ");
        $movRow->execute([$shiftId]);
        $mov     = $movRow->fetch(PDO::FETCH_ASSOC);
        $cashIn  = (float)$mov['cash_in'];
        $cashOut = (float)$mov['cash_out'];

        // ── Opening cash ────────────────────────────────────────
        $openRow = $db->prepare("SELECT opening_cash FROM shifts WHERE id = ?");
        $openRow->execute([$shiftId]);
        $openingCash = (float)$openRow->fetchColumn();

        // ── Expected cash formula ───────────────────────────────
        $expectedCash = $openingCash + $cashSales + $cashIn - $cashRefunds - $cashExpenses - $cashOut;

        return [
            'opening_cash'  => round($openingCash,  3),
            'cash_sales'    => round($cashSales,     3),
            'card_sales'    => round($cardSales,     3),
            'wallet_sales'  => round($walletSales,   3),
            'total_sales'   => round($totalSales,    3),
            'sales_count'   => $salesCount,
            'cash_refunds'  => round($cashRefunds,   3),
            'cash_expenses' => round($cashExpenses,  3),
            'cash_in'       => round($cashIn,        3),
            'cash_out'      => round($cashOut,       3),
            'expected_cash' => round($expectedCash,  3),
        ];
    }

    /**
     * Compute balance status from counted vs expected cash.
     */
    public static function balanceStatus(float $difference): string
    {
        if (abs($difference) < 0.001) return 'balanced';
        return $difference > 0 ? 'overage' : 'shortage';
    }
}
