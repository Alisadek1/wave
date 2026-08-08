-- Cash Management Refactor Migration

-- ── 1. Extend shifts table ──────────────────────────────────────
ALTER TABLE `shifts`
  ADD COLUMN IF NOT EXISTS `instapay_sales`  DECIMAL(12,3) NOT NULL DEFAULT 0.000 AFTER `wallet_sales`,
  ADD COLUMN IF NOT EXISTS `vodafone_sales`  DECIMAL(12,3) NOT NULL DEFAULT 0.000 AFTER `instapay_sales`,
  ADD COLUMN IF NOT EXISTS `cash_refunds`    DECIMAL(12,3) NOT NULL DEFAULT 0.000 AFTER `refunds_total`,
  ADD COLUMN IF NOT EXISTS `cash_in_total`   DECIMAL(12,3) NOT NULL DEFAULT 0.000 AFTER `cash_refunds`,
  ADD COLUMN IF NOT EXISTS `cash_out_total`  DECIMAL(12,3) NOT NULL DEFAULT 0.000 AFTER `cash_in_total`,
  ADD COLUMN IF NOT EXISTS `expected_cash`   DECIMAL(12,3)          DEFAULT NULL  AFTER `closing_cash`,
  ADD COLUMN IF NOT EXISTS `counted_cash`    DECIMAL(12,3)          DEFAULT NULL  AFTER `expected_cash`,
  ADD COLUMN IF NOT EXISTS `difference`      DECIMAL(12,3)          DEFAULT NULL  AFTER `counted_cash`,
  ADD COLUMN IF NOT EXISTS `balance_status`  ENUM('balanced','overage','shortage') DEFAULT NULL AFTER `difference`;

-- Back-fill counted_cash from existing closing_cash data
UPDATE `shifts` SET `counted_cash` = `closing_cash` WHERE `closing_cash` IS NOT NULL AND `counted_cash` IS NULL;

-- ── 2. Extend expenses payment_method ENUM ──────────────────────
-- Keep legacy values (visa, bank_transfer) for backward compat
ALTER TABLE `expenses`
  MODIFY COLUMN `payment_method` ENUM('cash','card','visa','bank','bank_transfer','instapay','vodafone_cash') NOT NULL DEFAULT 'cash';

-- ── 3. Create shift_cash_movements table ───────────────────────
CREATE TABLE IF NOT EXISTS `shift_cash_movements` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `shift_id`   INT UNSIGNED NOT NULL,
  `type`       ENUM('cash_in','cash_out') NOT NULL,
  `amount`     DECIMAL(12,3) NOT NULL,
  `reason`     VARCHAR(255)  DEFAULT NULL,
  `created_by` INT UNSIGNED  NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_cash_movements_shift` (`shift_id`),
  CONSTRAINT `fk_cash_movements_shift` FOREIGN KEY (`shift_id`) REFERENCES `shifts`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cash_movements_user`  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. New permissions ─────────────────────────────────────────
INSERT IGNORE INTO `permissions` (`name`, `display_name`, `module`) VALUES
('shifts.cash_movement', 'Add Cash In / Cash Out', 'shifts');

INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.name = 'shifts.cash_movement'
WHERE r.name IN ('owner', 'admin', 'cashier');
