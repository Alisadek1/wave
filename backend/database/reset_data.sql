-- Reset all business data, keep users/roles/permissions/settings
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE activity_logs;
TRUNCATE TABLE categories;
TRUNCATE TABLE companies;
TRUNCATE TABLE customers;
TRUNCATE TABLE drug_sync_logs;
TRUNCATE TABLE held_invoices;
TRUNCATE TABLE inventory_adjustments;
TRUNCATE TABLE medicines;
TRUNCATE TABLE medicine_batches;
TRUNCATE TABLE notifications;
TRUNCATE TABLE purchases;
TRUNCATE TABLE purchase_items;
TRUNCATE TABLE returns;
TRUNCATE TABLE return_items;
TRUNCATE TABLE sales;
TRUNCATE TABLE sale_items;
TRUNCATE TABLE suppliers;

SET FOREIGN_KEY_CHECKS = 1;
