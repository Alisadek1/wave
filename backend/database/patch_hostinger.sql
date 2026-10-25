-- Hostinger DB patch — run in phpMyAdmin SQL tab
-- Safe to run multiple times (uses IF NOT EXISTS)

SET FOREIGN_KEY_CHECKS = 0;

-- Add shift_id to sales if missing
ALTER TABLE sales
  ADD COLUMN IF NOT EXISTS `shift_id` int(10) unsigned DEFAULT NULL;

-- Create shifts table if missing
CREATE TABLE IF NOT EXISTS `shifts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(10) unsigned NOT NULL,
  `opening_cash` decimal(12,3) NOT NULL DEFAULT 0.000,
  `closing_cash` decimal(12,3) DEFAULT NULL,
  `expected_cash` decimal(12,3) DEFAULT NULL,
  `counted_cash` decimal(12,3) DEFAULT NULL,
  `difference` decimal(12,3) DEFAULT NULL,
  `balance_status` enum('balanced','overage','shortage') DEFAULT NULL,
  `cash_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `card_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `wallet_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `instapay_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `vodafone_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `refunds_total` decimal(12,3) NOT NULL DEFAULT 0.000,
  `net_sales` decimal(12,3) NOT NULL DEFAULT 0.000,
  `transactions_count` int(11) NOT NULL DEFAULT 0,
  `status` enum('open','closed') NOT NULL DEFAULT 'open',
  `notes` text DEFAULT NULL,
  `opened_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `closed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `shifts_user_id_foreign` (`user_id`),
  CONSTRAINT `shifts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add purchase_item_id to return_items if missing
ALTER TABLE return_items
  ADD COLUMN IF NOT EXISTS `purchase_item_id` int(10) unsigned DEFAULT NULL;

-- Add payment columns to returns if missing (needed for cash report)
ALTER TABLE returns
  ADD COLUMN IF NOT EXISTS `payment_method` enum('cash','visa','wallet','bank_transfer','mixed') DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `cash_amount` decimal(10,3) NOT NULL DEFAULT 0.000,
  ADD COLUMN IF NOT EXISTS `visa_amount` decimal(10,3) NOT NULL DEFAULT 0.000,
  ADD COLUMN IF NOT EXISTS `wallet_amount` decimal(10,3) NOT NULL DEFAULT 0.000,
  ADD COLUMN IF NOT EXISTS `bank_transfer_amount` decimal(10,3) NOT NULL DEFAULT 0.000;

SET FOREIGN_KEY_CHECKS = 1;
