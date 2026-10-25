-- ============================================================
-- WAVE — Reset shop data (keeps users, roles, permissions, settings)
-- Run this to start fresh with a new shop
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE `sale_items`;
TRUNCATE TABLE `sales`;
TRUNCATE TABLE `return_items`;
TRUNCATE TABLE `returns`;
TRUNCATE TABLE `held_invoices`;
TRUNCATE TABLE `purchase_items`;
TRUNCATE TABLE `purchases`;
TRUNCATE TABLE `medicine_batches`;
TRUNCATE TABLE `medicines`;
TRUNCATE TABLE `inventory_adjustments`;
TRUNCATE TABLE `categories`;
TRUNCATE TABLE `companies`;
TRUNCATE TABLE `suppliers`;
TRUNCATE TABLE `customers`;
TRUNCATE TABLE `notifications`;
TRUNCATE TABLE `activity_logs`;
TRUNCATE TABLE `drug_sync_logs`;

-- expenses & shifts (from migration)
TRUNCATE TABLE `shift_cash_movements`;
TRUNCATE TABLE `expenses`;
TRUNCATE TABLE `shifts`;
TRUNCATE TABLE `expense_categories`;

-- price history (from migration)
TRUNCATE TABLE `medicine_price_history`;

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'Shop data cleared successfully. Users, roles, permissions and settings are preserved.' AS status;
