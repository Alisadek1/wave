-- =============================================
-- WAVE — WOMEN'S ACCESSORIES STORE
-- =============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";
SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

-- =============================================
-- SETTINGS
-- =============================================
CREATE TABLE `settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` VARCHAR(100) NOT NULL,
  `value` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_settings_key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `settings` (`key`, `value`) VALUES
('pharmacy_name',       'Wave'),
('pharmacy_name_ar',    'ويف'),
('pharmacy_address',    ''),
('pharmacy_phone',      ''),
('pharmacy_email',      ''),
('pharmacy_logo',       ''),
('tax_enabled',         '1'),
('tax_rate',            '15'),
('currency',            'SAR'),
('currency_symbol',     'ر.س'),
('invoice_prefix',      'INV'),
('po_prefix',           'PO'),
('low_stock_threshold', '10'),
('receipt_header',      ''),
('receipt_footer',      'Thank you for shopping with us! — شكراً لتسوقكم معنا!'),
('printer_type',        'a4'),
('loyalty_points_rate', '1'),
('loyalty_points_value','0.01');

-- =============================================
-- ROLES
-- =============================================
CREATE TABLE `roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  `display_name` VARCHAR(100) NOT NULL,
  `description` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_roles_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `roles` (`name`, `display_name`, `description`) VALUES
('owner',             'Owner',             'Full access to all features'),
('admin',             'Administrator',     'Administrative access'),
('pharmacist',        'Store Manager',     'Manage products and inventory'),
('cashier',           'Cashier',           'Handle sales and payments'),
('inventory_manager', 'Inventory Manager', 'Manage stock and purchases');

-- =============================================
-- PERMISSIONS
-- =============================================
CREATE TABLE `permissions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `display_name` VARCHAR(150) NOT NULL,
  `module` VARCHAR(50) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_permissions_name` (`name`),
  KEY `idx_permissions_module` (`module`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `permissions` (`name`, `display_name`, `module`) VALUES
('dashboard.view',   'View Dashboard',        'dashboard'),
('categories.view',  'View Categories',       'categories'),
('categories.create','Create Categories',     'categories'),
('categories.edit',  'Edit Categories',       'categories'),
('categories.delete','Delete Categories',     'categories'),
('companies.view',   'View Brands',           'companies'),
('companies.create', 'Create Brands',         'companies'),
('companies.edit',   'Edit Brands',           'companies'),
('companies.delete', 'Delete Brands',         'companies'),
('suppliers.view',   'View Suppliers',        'suppliers'),
('suppliers.create', 'Create Suppliers',      'suppliers'),
('suppliers.edit',   'Edit Suppliers',        'suppliers'),
('suppliers.delete', 'Delete Suppliers',      'suppliers'),
('customers.view',   'View Customers',        'customers'),
('customers.create', 'Create Customers',      'customers'),
('customers.edit',   'Edit Customers',        'customers'),
('customers.delete', 'Delete Customers',      'customers'),
('medicines.view',   'View Products',         'medicines'),
('medicines.create', 'Create Products',       'medicines'),
('medicines.edit',   'Edit Products',         'medicines'),
('medicines.delete', 'Delete Products',       'medicines'),
('batches.view',     'View Batches',          'batches'),
('batches.create',   'Create Batches',        'batches'),
('batches.edit',     'Edit Batches',          'batches'),
('batches.delete',   'Delete Batches',        'batches'),
('purchases.view',   'View Purchases',        'purchases'),
('purchases.create', 'Create Purchases',      'purchases'),
('purchases.edit',   'Edit Purchases',        'purchases'),
('purchases.delete', 'Delete Purchases',      'purchases'),
('inventory.view',   'View Inventory',        'inventory'),
('inventory.adjust', 'Adjust Stock',          'inventory'),
('pos.access',       'Access POS',            'pos'),
('pos.discount',     'Apply Discount on POS', 'pos'),
('pos.refund',       'Process Refund',        'pos'),
('sales.view',       'View Sales',            'sales'),
('sales.delete',     'Delete Sales',          'sales'),
('returns.view',     'View Returns',          'returns'),
('returns.create',   'Create Returns',        'returns'),
('reports.view',     'View Reports',          'reports'),
('users.view',       'View Users',            'users'),
('users.create',     'Create Users',          'users'),
('users.edit',       'Edit Users',            'users'),
('users.delete',     'Delete Users',          'users'),
('settings.view',    'View Settings',         'settings'),
('settings.edit',    'Edit Settings',         'settings');

-- =============================================
-- ROLE PERMISSIONS
-- =============================================
CREATE TABLE `role_permissions` (
  `role_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`role_id`, `permission_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `role_permissions` (`role_id`, `permission_id`) SELECT 1, id FROM `permissions`;
INSERT INTO `role_permissions` (`role_id`, `permission_id`) SELECT 2, id FROM `permissions`;
INSERT INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 3, id FROM `permissions` WHERE `name` IN (
  'dashboard.view','medicines.view','medicines.edit','batches.view',
  'inventory.view','pos.access','pos.discount','pos.refund',
  'sales.view','returns.view','returns.create','customers.view','customers.create'
);
INSERT INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 4, id FROM `permissions` WHERE `name` IN (
  'dashboard.view','medicines.view','pos.access','sales.view',
  'customers.view','customers.create','returns.view','returns.create'
);
INSERT INTO `role_permissions` (`role_id`, `permission_id`)
SELECT 5, id FROM `permissions` WHERE `name` IN (
  'dashboard.view','medicines.view','medicines.create','medicines.edit',
  'batches.view','batches.create','batches.edit','purchases.view',
  'purchases.create','purchases.edit','inventory.view','inventory.adjust',
  'suppliers.view','categories.view','companies.view','reports.view'
);

-- =============================================
-- USERS
-- =============================================
CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `username` VARCHAR(50) NOT NULL,
  `email` VARCHAR(150) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(20),
  `avatar` VARCHAR(255),
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `last_login` TIMESTAMP NULL,
  `password_reset_token` VARCHAR(255),
  `password_reset_expires` TIMESTAMP NULL,
  `refresh_token` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_username` (`username`),
  UNIQUE KEY `uk_users_email` (`email`),
  KEY `idx_users_role` (`role_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- password: Admin@123
INSERT INTO `users` (`role_id`, `name`, `username`, `email`, `password`) VALUES
(1, 'System Owner', 'owner', 'owner@wave.com', '$2y$12$lBH7s1pzJbUjpXbSRX07kuZLaCo185x/Fol7Uyfg3fOdyES88PUSe');

-- =============================================
-- USER PERMISSIONS
-- =============================================
CREATE TABLE `user_permissions` (
  `user_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  `granted` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`user_id`, `permission_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`permission_id`) REFERENCES `permissions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- ACTIVITY LOG
-- =============================================
CREATE TABLE `activity_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED,
  `action` VARCHAR(100) NOT NULL,
  `model` VARCHAR(50),
  `model_id` INT UNSIGNED,
  `description` TEXT,
  `ip_address` VARCHAR(45),
  `user_agent` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_activity_user` (`user_id`),
  KEY `idx_activity_model` (`model`, `model_id`),
  KEY `idx_activity_created` (`created_at`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- CATEGORIES
-- =============================================
CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `name_ar` VARCHAR(100),
  `description` TEXT,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_categories_name` (`name`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `categories` (`id`, `name`, `name_ar`, `description`, `is_active`, `created_by`) VALUES
(1,  'Handbags & Clutches',  'حقائب يد وكلاتش',      'Tote bags, shoulder bags, crossbody and evening clutches', 1, 1),
(2,  'Jewelry & Earrings',   'مجوهرات وأقراط',        'Necklaces, rings, earrings and statement pieces',          1, 1),
(3,  'Scarves & Hijabs',     'أوشحة وحجابات',         'Silk scarves, chiffon hijabs and printed shawls',          1, 1),
(4,  'Hair Accessories',     'إكسسوارات الشعر',       'Clips, scrunchies, headbands and pins',                    1, 1),
(5,  'Beauty Accessories',   'أدوات التجميل',         'Makeup brushes, mirrors, lash tools and beauty sets',      1, 1),
(6,  'Sunglasses',           'نظارات شمسية',          'Cat-eye, oversized and sporty frames for women',           1, 1),
(7,  'Ladies Watches',       'ساعات نسائية',           'Elegant and casual women''s timepieces',                   1, 1),
(8,  'Wallets & Card Holders','محافظ وحاملات بطاقات', 'Slim wallets, coin purses and card holders',               1, 1),
(9,  'Perfumes & Body Mist', 'عطور ومستحضرات',        'Floral and oriental perfumes, body mists and sprays',      1, 1),
(10, 'Bracelets & Bangles',  'أساور وبانجل',          'Gold, silver, crystal and beaded bracelets',               1, 1),
(11, 'Phone Cases',          'جرابات الجوال',          'Stylish and feminine phone cases and covers',              1, 1),
(12, 'Hair Care Tools',      'أدوات العناية بالشعر',  'Mini straighteners, curlers and hair care gadgets',        1, 1);

-- =============================================
-- COMPANIES (Brands)
-- =============================================
CREATE TABLE `companies` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `name_ar` VARCHAR(150),
  `country` VARCHAR(100),
  `phone` VARCHAR(20),
  `email` VARCHAR(150),
  `address` TEXT,
  `website` VARCHAR(255),
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_companies_name` (`name`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `companies` (`id`, `name`, `name_ar`, `country`, `phone`, `email`, `website`, `is_active`, `created_by`) VALUES
(1, 'Zara',          'زارا',          'Spain',        '', 'info@zara.com',       'www.zara.com',       1, 1),
(2, 'Pandora',       'باندورا',       'Denmark',      '', 'info@pandora.net',    'www.pandora.net',    1, 1),
(3, 'Swarovski',     'سواروفسكي',     'Austria',      '', 'info@swarovski.com',  'www.swarovski.com',  1, 1),
(4, 'Michael Kors',  'مايكل كورس',    'USA',          '', 'info@michaelkors.com','www.michaelkors.com',1, 1),
(5, 'Guess',         'جيس',           'USA',          '', 'info@guess.com',      'www.guess.com',      1, 1),
(6, 'Ray-Ban',       'راي-بان',       'Italy',        '', 'info@ray-ban.com',    'www.ray-ban.com',    1, 1),
(7, 'H&M',           'إتش آند إم',    'Sweden',       '', 'info@hm.com',         'www.hm.com',         1, 1),
(8, 'Wave',          'ويف',           'Saudi Arabia', '', 'info@wave.com',       '',                   1, 1);

-- =============================================
-- SUPPLIERS
-- =============================================
CREATE TABLE `suppliers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `company_name` VARCHAR(150),
  `phone` VARCHAR(20),
  `email` VARCHAR(150),
  `address` TEXT,
  `tax_number` VARCHAR(50),
  `credit_limit` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `balance` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_suppliers_name` (`name`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `suppliers` (`id`, `name`, `company_name`, `phone`, `email`, `address`, `tax_number`, `credit_limit`, `balance`, `is_active`, `created_by`) VALUES
(1, 'Nora Al-Rashidi',   'Al-Rashidi Fashion Trading',  '+966-55-100-2001', 'nora@alrashidi.com',    'Riyadh, Saudi Arabia',  '310001234500001', 80000.00,     0.00, 1, 1),
(2, 'Sara Al-Zahrani',   'Gulf Style Co.',               '+966-55-200-3002', 'sara@gulfstyle.com',    'Jeddah, Saudi Arabia',  '310002345600002', 60000.00,  1200.00, 1, 1),
(3, 'Lina Al-Otaibi',    'Elegance Arabia',              '+966-55-300-4003', 'lina@elegancear.com',   'Dammam, Saudi Arabia',  '310003456700003', 50000.00,     0.00, 1, 1),
(4, 'Hana Al-Ghamdi',    'Chic Accessories KSA',         '+966-55-400-5004', 'hana@chicacc.com',      'Riyadh, Saudi Arabia',  '310004567800004', 40000.00,   600.00, 1, 1),
(5, 'Reem Al-Harbi',     'Trend Suppliers Arabia',       '+966-55-500-6005', 'reem@trendsup.com.sa',  'Riyadh, Saudi Arabia',  '310005678900005', 70000.00,     0.00, 1, 1);

-- =============================================
-- CUSTOMERS
-- =============================================
CREATE TABLE `customers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(150) NOT NULL,
  `phone` VARCHAR(20),
  `email` VARCHAR(150),
  `date_of_birth` DATE,
  `gender` ENUM('male','female','other'),
  `address` TEXT,
  `id_number` VARCHAR(50),
  `loyalty_points` INT NOT NULL DEFAULT 0,
  `total_purchases` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  `notes` TEXT,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_customers_phone` (`phone`),
  KEY `idx_customers_name` (`name`),
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `customers` (`id`, `name`, `phone`, `email`, `date_of_birth`, `gender`, `address`, `loyalty_points`, `total_purchases`, `is_active`, `created_by`) VALUES
(1,  'Noura Al-Salem',     '+966-50-111-2001', 'noura@email.com',    '1995-03-15', 'female', 'Riyadh, Al-Malaz',    450,  2250.00, 1, 1),
(2,  'Sara Al-Dosari',     '+966-55-222-3002', 'sara@email.com',     '1992-07-22', 'female', 'Riyadh, Al-Olaya',    280,  1400.00, 1, 1),
(3,  'Fatima Al-Shammar',  '+966-53-333-4003', 'fatima@email.com',   '1988-11-05', 'female', 'Jeddah, Al-Balad',    620,  3100.00, 1, 1),
(4,  'Lina Al-Qahtani',    '+966-54-444-5004', 'lina@email.com',     '1998-01-30', 'female', 'Dammam, Al-Khobar',   130,   650.00, 1, 1),
(5,  'Hana Al-Ghamdi',     '+966-56-555-6005', 'hana@email.com',     '1990-09-18', 'female', 'Riyadh, Alhazm',      380,  1900.00, 1, 1),
(6,  'Reem Al-Zahrani',    '+966-57-666-7006', 'reem@email.com',     '1996-04-12', 'female', 'Riyadh, Al-Rabwa',    710,  3550.00, 1, 1),
(7,  'Mona Al-Mutairi',    '+966-58-777-8007', 'mona@email.com',     '1985-12-25', 'female', 'Riyadh, Al-Nakheel',  95,    475.00, 1, 1),
(8,  'Dana Al-Otaibi',     '+966-59-888-9008', 'dana@email.com',     '1999-06-08', 'female', 'Jeddah, Al-Rawdah',   190,   950.00, 1, 1),
(9,  'Nada Al-Harbi',      '+966-50-999-0009', 'nada@email.com',     '1993-02-14', 'female', 'Medina, Al-Aziziyah',  0,     0.00, 1, 1),
(10, 'Rana Al-Rashidi',    '+966-55-000-1010', 'rana@email.com',     '2001-08-20', 'female', 'Riyadh, Al-Wurud',    160,   800.00, 1, 1);

-- =============================================
-- MEDICINES (Products)
-- =============================================
CREATE TABLE `medicines` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category_id` INT UNSIGNED,
  `company_id` INT UNSIGNED,
  `name` VARCHAR(200) NOT NULL,
  `name_ar` VARCHAR(200),
  `scientific_name` VARCHAR(200),
  `barcode` VARCHAR(100),
  `sku` VARCHAR(100),
  `dosage_form` VARCHAR(50),
  `strength` VARCHAR(100),
  `unit` VARCHAR(50) DEFAULT 'Piece',
  `purchase_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `selling_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `public_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `minimum_stock` INT NOT NULL DEFAULT 10,
  `prescription_required` TINYINT(1) NOT NULL DEFAULT 0,
  `controlled_drug` TINYINT(1) NOT NULL DEFAULT 0,
  `image` VARCHAR(255),
  `description` TEXT,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_medicines_barcode` (`barcode`),
  UNIQUE KEY `uk_medicines_sku` (`sku`),
  KEY `idx_medicines_category` (`category_id`),
  KEY `idx_medicines_company` (`company_id`),
  KEY `idx_medicines_name` (`name`),
  FULLTEXT KEY `ft_medicines_search` (`name`, `name_ar`, `scientific_name`, `barcode`, `sku`),
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`company_id`) REFERENCES `companies`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- id | cat | brand | name (EN) | name (AR) | model/style | barcode | sku | type | size/specs | unit | cost | price | min_stock
INSERT INTO `medicines` (`id`, `category_id`, `company_id`, `name`, `name_ar`, `scientific_name`, `barcode`, `sku`, `dosage_form`, `strength`, `unit`, `purchase_price`, `selling_price`, `minimum_stock`, `prescription_required`, `controlled_drug`, `is_active`, `created_by`) VALUES
-- ── Handbags & Clutches ──────────────────────────────────────────────────────
(1,  1, 1, 'Zara Leather Tote Bag',              'حقيبة توت جلد زارا',          '', '6900101001001', 'ZR-TOTE-BLK',  'Tote Bag',     'Large / Black',       'Piece', 120.000, 295.000, 5,  0, 0, 1, 1),
(2,  1, 1, 'Zara Mini Crossbody Bag',            'حقيبة كروس ميني زارا',        '', '6900101001002', 'ZR-MINI-TAN',  'Crossbody',    'Mini / Tan',          'Piece',  85.000, 210.000, 8,  0, 0, 1, 1),
(3,  1, 4, 'Michael Kors Jet Set Tote',          'حقيبة جيت سيت مايكل كورس',   '', '6900101001003', 'MK-JSET-BRN',  'Tote Bag',     'Medium / Brown',      'Piece', 380.000, 850.000, 3,  0, 0, 1, 1),
(4,  1, 5, 'Guess Evening Clutch',               'كلاتش سهرة جيس',              '', '6900101001004', 'GS-EVNG-GLD',  'Clutch',       'Small / Gold',        'Piece',  65.000, 165.000, 8,  0, 0, 1, 1),
(5,  1, 7, 'H&M Quilted Shoulder Bag',           'حقيبة كتف منقوشة إتش آند إم', '', '6900101001005', 'HM-QSHL-BLK',  'Shoulder Bag', 'Medium / Black',      'Piece',  55.000, 140.000, 10, 0, 0, 1, 1),
-- ── Jewelry & Earrings ───────────────────────────────────────────────────────
(6,  2, 2, 'Pandora Rose Gold Charm Necklace',   'قلادة باندورا ذهب وردي',      '', '6900102002001', 'PD-RGNK-001',  'Necklace',     '45cm / Rose Gold',    'Piece', 180.000, 420.000, 5,  0, 0, 1, 1),
(7,  2, 3, 'Swarovski Crystal Drop Earrings',    'أقراط كريستال سواروفسكي',     '', '6900102002002', 'SW-CDER-CLR',  'Earrings',     'Drop / Silver',       'Piece', 120.000, 285.000, 8,  0, 0, 1, 1),
(8,  2, 2, 'Pandora Sterling Silver Ring',       'خاتم فضة استرليني باندورا',   '', '6900102002003', 'PD-SSRG-52',   'Ring',         'Size 52 / Silver',    'Piece',  95.000, 230.000, 8,  0, 0, 1, 1),
(9,  2, 8, 'Wave Pearl Stud Earrings',           'أقراط لؤلؤ ويف',              '', '6900102002004', 'WV-PEAR-STD',  'Earrings',     'Stud / White Pearl',  'Piece',  18.000,  55.000, 15, 0, 0, 1, 1),
(10, 2, 3, 'Swarovski Pendant Necklace',         'قلادة بلورية سواروفسكي',      '', '6900102002005', 'SW-PDNK-CLR',  'Necklace',     '40cm / Crystal',      'Piece', 150.000, 360.000, 6,  0, 0, 1, 1),
-- ── Scarves & Hijabs ─────────────────────────────────────────────────────────
(11, 3, 1, 'Zara Satin Hijab Scarf',             'حجاب ساتان زارا',             '', '6900103003001', 'ZR-STHJ-BLK',  'Hijab',        '180x75cm / Black',    'Piece',  25.000,  65.000, 20, 0, 0, 1, 1),
(12, 3, 1, 'Zara Floral Chiffon Scarf',          'وشاح شيفون زهري زارا',        '', '6900103003002', 'ZR-FLCH-PNK',  'Scarf',        '170x70cm / Pink',     'Piece',  30.000,  78.000, 15, 0, 0, 1, 1),
(13, 3, 7, 'H&M Printed Square Scarf',           'وشاح مربع مطبوع إتش آند إم',  '', '6900103003003', 'HM-PRSQ-MUL',  'Scarf',        '90x90cm / Multicolor','Piece',  20.000,  55.000, 20, 0, 0, 1, 1),
(14, 3, 8, 'Wave Silk Blend Shawl',              'شال حرير مزيج ويف',           '', '6900103003004', 'WV-SLSW-BEG',  'Shawl',        '200x80cm / Beige',    'Piece',  35.000,  90.000, 15, 0, 0, 1, 1),
-- ── Hair Accessories ─────────────────────────────────────────────────────────
(15, 4, 8, 'Wave Pearl Hair Clip Set (3 pcs)',   'طقم مشابك لؤلؤ ويف 3 قطع',   '', '6900104004001', 'WV-PHC3-WHT',  'Hair Clips',   '3-piece / White Pearl','Set',    12.000,  35.000, 20, 0, 0, 1, 1),
(16, 4, 8, 'Wave Satin Scrunchie Set (5 pcs)',   'طقم مطاط ساتان ويف 5 قطع',   '', '6900104004002', 'WV-SSC5-MUL',  'Scrunchies',   '5-piece / Mixed',     'Set',     8.000,  25.000, 25, 0, 0, 1, 1),
(17, 4, 7, 'H&M Embellished Headband',           'طوق رأس مزيّن إتش آند إم',    '', '6900104004003', 'HM-EMHB-GLD',  'Headband',     'Wide / Gold Trim',    'Piece',  15.000,  42.000, 15, 0, 0, 1, 1),
(18, 4, 8, 'Wave Butterfly Hair Pins (6 pcs)',   'دبابيس فراشة ويف 6 قطع',     '', '6900104004004', 'WV-BHP6-MUL',  'Hair Pins',    '6-piece / Mixed',     'Set',    10.000,  28.000, 20, 0, 0, 1, 1),
-- ── Beauty Accessories ───────────────────────────────────────────────────────
(19, 5, 8, 'Wave 12-Piece Makeup Brush Set',     'طقم فرش مكياج ويف 12 قطعة',  '', '6900105005001', 'WV-MKB12-PNK', 'Brush Set',    '12-piece / Pink',     'Set',    35.000,  89.000, 10, 0, 0, 1, 1),
(20, 5, 8, 'Wave LED Makeup Mirror',             'مرآة مكياج LED ويف',          '', '6900105005002', 'WV-LEDM-WHT',  'Mirror',       '10x Magnify / White', 'Piece',  28.000,  75.000, 10, 0, 0, 1, 1),
(21, 5, 8, 'Wave Eyelash Curler',                'ملقط رموش ويف',               '', '6900105005003', 'WV-ELCR-001',  'Tool',         'Stainless Steel',     'Piece',  12.000,  32.000, 15, 0, 0, 1, 1),
(22, 5, 8, 'Wave Magnetic Lash Kit (3 pairs)',   'طقم رموش مغناطيسية ويف',      '', '6900105005004', 'WV-MLK3-BLK',  'Lash Kit',     '3 pairs / Black',     'Set',    20.000,  55.000, 12, 0, 0, 1, 1),
-- ── Sunglasses ───────────────────────────────────────────────────────────────
(23, 6, 6, 'Ray-Ban Cat Eye Sunglasses',         'نظارة كات آي راي-بان',        '', '6900106006001', 'RB-CATI-BLK',  'Sunglasses',   'Cat Eye / Black',     'Piece', 160.000, 390.000, 5,  0, 0, 1, 1),
(24, 6, 5, 'Guess Oversized Sunglasses',         'نظارة أوفرسايز جيس',          '', '6900106006002', 'GS-OVRS-GLD',  'Sunglasses',   'Oversized / Gold',    'Piece',  70.000, 175.000, 8,  0, 0, 1, 1),
(25, 6, 8, 'Wave Butterfly Sunglasses',          'نظارة فراشة ويف',             '', '6900106006003', 'WV-BTFL-BRN',  'Sunglasses',   'Butterfly / Brown',   'Piece',  30.000,  85.000, 12, 0, 0, 1, 1),
-- ── Ladies Watches ───────────────────────────────────────────────────────────
(26, 7, 4, 'Michael Kors Lexington Watch',       'ساعة ليكسنغتون مايكل كورس',  '', '6900107007001', 'MK-LEXW-GLD',  'Watch',        '28mm / Rose Gold',    'Piece', 480.000,1100.000, 3,  0, 0, 1, 1),
(27, 7, 5, 'Guess Sparkle Quartz Watch',         'ساعة كوارتز سباركل جيس',     '', '6900107007002', 'GS-SPQW-SLV',  'Watch',        '36mm / Silver',       'Piece', 180.000, 430.000, 5,  0, 0, 1, 1),
-- ── Wallets & Card Holders ───────────────────────────────────────────────────
(28, 8, 1, 'Zara Zip-Around Leather Wallet',     'محفظة جلد زارا',              '', '6900108008001', 'ZR-ZAWL-BLK',  'Wallet',       'Zip-Around / Black',  'Piece',  45.000, 115.000, 10, 0, 0, 1, 1),
(29, 8, 8, 'Wave Card Holder Slim Wallet',       'حامل بطاقات ويف',             '', '6900108008002', 'WV-CHSL-PNK',  'Card Holder',  'Slim / Pink',         'Piece',  15.000,  42.000, 15, 0, 0, 1, 1),
-- ── Perfumes & Body Mist ─────────────────────────────────────────────────────
(30, 9, 8, 'Wave Rose & Oud Body Mist 250ml',    'بودي ميست ورد وعود ويف',      '', '6900109009001', 'WV-ROUM-250',  'Body Mist',    '250ml / Floral Oud',  'Bottle', 22.000,  65.000, 15, 0, 0, 1, 1),
(31, 9, 8, 'Wave Jasmine Eau de Parfum 50ml',    'عطر ياسمين ويف 50 مل',        '', '6900109009002', 'WV-JASP-050',  'Perfume',      '50ml / Floral',       'Bottle', 55.000, 145.000, 10, 0, 0, 1, 1),
-- ── Bracelets & Bangles ──────────────────────────────────────────────────────
(32,10, 2, 'Pandora Moments Charm Bracelet',     'أسورة تشارم باندورا',         '', '6900110010001', 'PD-MCBR-SLV',  'Bracelet',     '19cm / Silver',       'Piece', 120.000, 290.000, 6,  0, 0, 1, 1),
(33,10, 3, 'Swarovski Constella Bangle',         'بانجل كونستيلا سواروفسكي',    '', '6900110010002', 'SW-CNBL-GLD',  'Bangle',       'Gold / Crystal',      'Piece', 140.000, 330.000, 5,  0, 0, 1, 1),
(34,10, 8, 'Wave Beaded Stretch Bracelet Set',   'طقم أساور خرز ويف',           '', '6900110010003', 'WV-BSBR-MUL',  'Bracelet Set', '3-piece / Mixed',     'Set',    15.000,  42.000, 20, 0, 0, 1, 1),
-- ── Phone Cases ──────────────────────────────────────────────────────────────
(35,11, 8, 'Wave Floral iPhone 15 Pro Case',     'جراب زهري آيفون 15 برو ويف',  '', '6900111011001', 'WV-FLP15-PNK', 'Phone Case',   'iPhone 15 Pro / Pink','Piece',  12.000,  35.000, 20, 0, 0, 1, 1),
(36,11, 8, 'Wave Glitter Samsung S24 Case',      'جراب جلتر سامسونج S24 ويف',   '', '6900111011002', 'WV-GLS24-GLD', 'Phone Case',   'S24 / Gold Glitter',  'Piece',  12.000,  35.000, 20, 0, 0, 1, 1),
-- ── Hair Care Tools ──────────────────────────────────────────────────────────
(37,12, 8, 'Wave Mini Hair Straightener',        'مكواة شعر مصغرة ويف',         '', '6900112012001', 'WV-MNST-PNK',  'Straightener', 'Mini / Pink / 150°C', 'Piece',  55.000, 140.000, 8,  0, 0, 1, 1),
(38,12, 8, 'Wave Ceramic Curling Wand 25mm',     'جهاز تجعيل شعر سيراميك ويف',  '', '6900112012002', 'WV-CECW-25',   'Curler',       '25mm / Ceramic',      'Piece',  65.000, 160.000, 8,  0, 0, 1, 1);

-- =============================================
-- MEDICINE BATCHES
-- =============================================
CREATE TABLE `medicine_batches` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `medicine_id` INT UNSIGNED NOT NULL,
  `supplier_id` INT UNSIGNED,
  `batch_number` VARCHAR(100) NOT NULL,
  `manufacturing_date` DATE,
  `purchase_price` DECIMAL(10,3) NOT NULL,
  `selling_price` DECIMAL(10,3) NOT NULL,
  `public_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `quantity` INT NOT NULL DEFAULT 0,
  `initial_quantity` INT NOT NULL DEFAULT 0,
  `notes` TEXT,
  `created_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_medicine_number` (`medicine_id`, `batch_number`),
  KEY `idx_batch_medicine` (`medicine_id`),
  KEY `idx_batch_supplier` (`supplier_id`),
  KEY `idx_batch_quantity` (`quantity`),
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `medicine_batches` (`id`, `medicine_id`, `supplier_id`, `batch_number`, `manufacturing_date`, `purchase_price`, `selling_price`, `quantity`, `initial_quantity`, `created_by`) VALUES
(1,  1,  1, 'ZR-TOTE-2025-01',  '2025-01-01', 120.000, 295.000, 18,  18,  1),
(2,  2,  1, 'ZR-MINI-2025-01',  '2025-01-01',  85.000, 210.000, 22,  22,  1),
(3,  3,  4, 'MK-JSET-2025-01',  '2025-02-01', 380.000, 850.000,  8,   8,  1),
(4,  4,  2, 'GS-EVNG-2025-01',  '2025-01-01',  65.000, 165.000, 20,  20,  1),
(5,  5,  5, 'HM-QSHL-2025-01',  '2025-01-01',  55.000, 140.000, 28,  28,  1),
(6,  6,  4, 'PD-RGNK-2025-01',  '2025-01-01', 180.000, 420.000, 14,  14,  1),
(7,  7,  3, 'SW-CDER-2025-01',  '2025-01-01', 120.000, 285.000, 18,  18,  1),
(8,  8,  4, 'PD-SSRG-2025-01',  '2025-02-01',  95.000, 230.000, 20,  20,  1),
(9,  9,  5, 'WV-PEAR-2025-01',  '2025-01-01',  18.000,  55.000, 40,  40,  1),
(10,10,  3, 'SW-PDNK-2025-01',  '2025-01-01', 150.000, 360.000, 15,  15,  1),
(11,11,  1, 'ZR-STHJ-2025-01',  '2025-01-01',  25.000,  65.000, 50,  50,  1),
(12,12,  1, 'ZR-FLCH-2025-01',  '2025-01-01',  30.000,  78.000, 40,  40,  1),
(13,13,  5, 'HM-PRSQ-2025-01',  '2025-01-01',  20.000,  55.000, 45,  45,  1),
(14,14,  5, 'WV-SLSW-2025-01',  '2025-01-01',  35.000,  90.000, 35,  35,  1),
(15,15,  5, 'WV-PHC3-2025-01',  '2025-01-01',  12.000,  35.000, 50,  50,  1),
(16,16,  5, 'WV-SSC5-2025-01',  '2025-01-01',   8.000,  25.000, 60,  60,  1),
(17,17,  5, 'HM-EMHB-2025-01',  '2025-02-01',  15.000,  42.000, 35,  35,  1),
(18,18,  5, 'WV-BHP6-2025-01',  '2025-01-01',  10.000,  28.000, 55,  55,  1),
(19,19,  5, 'WV-MKB12-2025-01', '2025-01-01',  35.000,  89.000, 25,  25,  1),
(20,20,  5, 'WV-LEDM-2025-01',  '2025-01-01',  28.000,  75.000, 22,  22,  1),
(21,21,  5, 'WV-ELCR-2025-01',  '2025-01-01',  12.000,  32.000, 30,  30,  1),
(22,22,  5, 'WV-MLK3-2025-01',  '2025-02-01',  20.000,  55.000, 28,  28,  1),
(23,23,  3, 'RB-CATI-2025-01',  '2025-01-01', 160.000, 390.000, 12,  12,  1),
(24,24,  2, 'GS-OVRS-2025-01',  '2025-01-01',  70.000, 175.000, 20,  20,  1),
(25,25,  5, 'WV-BTFL-2025-01',  '2025-01-01',  30.000,  85.000, 30,  30,  1),
(26,26,  4, 'MK-LEXW-2025-01',  '2025-01-01', 480.000,1100.000,  6,   6,  1),
(27,27,  2, 'GS-SPQW-2025-01',  '2025-01-01', 180.000, 430.000, 10,  10,  1),
(28,28,  1, 'ZR-ZAWL-2025-01',  '2025-01-01',  45.000, 115.000, 25,  25,  1),
(29,29,  5, 'WV-CHSL-2025-01',  '2025-01-01',  15.000,  42.000, 40,  40,  1),
(30,30,  5, 'WV-ROUM-2025-01',  '2025-01-01',  22.000,  65.000, 40,  40,  1),
(31,31,  5, 'WV-JASP-2025-01',  '2025-01-01',  55.000, 145.000, 25,  25,  1),
(32,32,  4, 'PD-MCBR-2025-01',  '2025-01-01', 120.000, 290.000, 15,  15,  1),
(33,33,  3, 'SW-CNBL-2025-01',  '2025-01-01', 140.000, 330.000, 12,  12,  1),
(34,34,  5, 'WV-BSBR-2025-01',  '2025-01-01',  15.000,  42.000, 45,  45,  1),
(35,35,  5, 'WV-FLP15-2025-01', '2025-01-01',  12.000,  35.000, 50,  50,  1),
(36,36,  5, 'WV-GLS24-2025-01', '2025-01-01',  12.000,  35.000, 50,  50,  1),
(37,37,  5, 'WV-MNST-2025-01',  '2025-01-01',  55.000, 140.000, 18,  18,  1),
(38,38,  5, 'WV-CECW-2025-01',  '2025-02-01',  65.000, 160.000, 15,  15,  1);

-- =============================================
-- PURCHASE ORDERS
-- =============================================
CREATE TABLE `purchases` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_number` VARCHAR(50) NOT NULL,
  `supplier_id` INT UNSIGNED,
  `user_id` INT UNSIGNED,
  `subtotal` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `discount_type` ENUM('fixed','percentage') DEFAULT 'fixed',
  `discount_value` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `discount_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `total` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `paid_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `due_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `status` ENUM('draft','ordered','received','partial','cancelled') DEFAULT 'received',
  `payment_status` ENUM('unpaid','partial','paid') DEFAULT 'paid',
  `notes` TEXT,
  `purchase_date` DATE NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_purchases_invoice` (`invoice_number`),
  KEY `idx_purchases_supplier` (`supplier_id`),
  KEY `idx_purchases_user` (`user_id`),
  KEY `idx_purchases_date` (`purchase_date`),
  KEY `idx_purchases_status` (`status`),
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `purchases` (`id`, `invoice_number`, `supplier_id`, `user_id`, `subtotal`, `discount_type`, `discount_value`, `discount_amount`, `tax_rate`, `tax_amount`, `total`, `paid_amount`, `due_amount`, `status`, `payment_status`, `purchase_date`) VALUES
(1, 'PO-20250115-0001', 1, 1,  6050.000, 'fixed',      0.000,   0.000, 15.00,  907.500,  6957.500,  6957.500,     0.000, 'received', 'paid',    '2025-01-15'),
(2, 'PO-20250201-0001', 4, 1,  8120.000, 'percentage', 5.000, 406.000, 15.00, 1157.100,  8871.100,  8871.100,     0.000, 'received', 'paid',    '2025-02-01'),
(3, 'PO-20250401-0001', 3, 1,  5240.000, 'fixed',      0.000,   0.000, 15.00,  786.000,  6026.000,  5000.000,  1026.000, 'received', 'partial', '2025-04-01'),
(4, 'PO-20250601-0001', 5, 1,  4380.000, 'fixed',      0.000,   0.000, 15.00,  657.000,  5037.000,  5037.000,     0.000, 'received', 'paid',    '2025-06-01'),
(5, 'PO-20260101-0001', 2, 1,  7650.000, 'percentage', 3.000, 229.500, 15.00, 1113.825,  8534.325,  8534.325,     0.000, 'received', 'paid',    '2026-01-10'),
(6, 'PO-20260601-0001', 5, 1,  3200.000, 'fixed',      0.000,   0.000, 15.00,  480.000,  3680.000,  3680.000,     0.000, 'received', 'paid',    '2026-06-01');

-- =============================================
-- PURCHASE ITEMS
-- =============================================
CREATE TABLE `purchase_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `purchase_id` INT UNSIGNED NOT NULL,
  `medicine_id` INT UNSIGNED NOT NULL,
  `batch_id` INT UNSIGNED,
  `batch_number` VARCHAR(100),
  `quantity` INT NOT NULL,
  `purchase_price` DECIMAL(10,3) NOT NULL,
  `selling_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `public_price` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `remaining_quantity` INT NOT NULL DEFAULT 0,
  `subtotal` DECIMAL(12,3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_purchase_items_purchase` (`purchase_id`),
  KEY `idx_purchase_items_medicine` (`medicine_id`),
  KEY `idx_purchase_items_batch` (`batch_id`),
  FOREIGN KEY (`purchase_id`) REFERENCES `purchases`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`),
  FOREIGN KEY (`batch_id`) REFERENCES `medicine_batches`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `purchase_items` (`id`, `purchase_id`, `medicine_id`, `batch_id`, `batch_number`, `quantity`, `purchase_price`, `selling_price`, `subtotal`) VALUES
(1,  1, 1,  1,  'ZR-TOTE-2025-01',  18, 120.000, 295.000, 2160.000),
(2,  1, 2,  2,  'ZR-MINI-2025-01',  22,  85.000, 210.000, 1870.000),
(3,  1, 11, 11, 'ZR-STHJ-2025-01',  50,  25.000,  65.000, 1250.000),
(4,  1, 12, 12, 'ZR-FLCH-2025-01',  40,  30.000,  78.000, 1200.000),
(5,  2, 6,  6,  'PD-RGNK-2025-01',  14, 180.000, 420.000, 2520.000),
(6,  2, 8,  8,  'PD-SSRG-2025-01',  20,  95.000, 230.000, 1900.000),
(7,  2, 32, 32, 'PD-MCBR-2025-01',  15, 120.000, 290.000, 1800.000),
(8,  2, 3,  3,  'MK-JSET-2025-01',   8, 380.000, 850.000, 3040.000),
(9,  3, 7,  7,  'SW-CDER-2025-01',  18, 120.000, 285.000, 2160.000),
(10, 3, 10, 10, 'SW-PDNK-2025-01',  15, 150.000, 360.000, 2250.000),
(11, 3, 33, 33, 'SW-CNBL-2025-01',  12, 140.000, 330.000, 1680.000),
(12, 4, 15, 15, 'WV-PHC3-2025-01',  50,  12.000,  35.000,  600.000),
(13, 4, 16, 16, 'WV-SSC5-2025-01',  60,   8.000,  25.000,  480.000),
(14, 4, 19, 19, 'WV-MKB12-2025-01', 25,  35.000,  89.000,  875.000),
(15, 4, 30, 30, 'WV-ROUM-2025-01',  40,  22.000,  65.000,  880.000),
(16, 4, 31, 31, 'WV-JASP-2025-01',  25,  55.000, 145.000, 1375.000),
(17, 5, 23, 23, 'RB-CATI-2025-01',  12, 160.000, 390.000, 1920.000),
(18, 5, 24, 24, 'GS-OVRS-2025-01',  20,  70.000, 175.000, 1400.000),
(19, 5, 26, 26, 'MK-LEXW-2025-01',   6, 480.000,1100.000, 2880.000),
(20, 5, 27, 27, 'GS-SPQW-2025-01',  10, 180.000, 430.000, 1800.000),
(21, 6, 37, 37, 'WV-MNST-2025-01',  18,  55.000, 140.000,  990.000),
(22, 6, 38, 38, 'WV-CECW-2025-01',  15,  65.000, 160.000,  975.000),
(23, 6, 35, 35, 'WV-FLP15-2025-01', 50,  12.000,  35.000,  600.000),
(24, 6, 36, 36, 'WV-GLS24-2025-01', 50,  12.000,  35.000,  600.000);

-- =============================================
-- SALES
-- =============================================
CREATE TABLE `sales` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_number` VARCHAR(50) NOT NULL,
  `customer_id` INT UNSIGNED,
  `user_id` INT UNSIGNED,
  `subtotal` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `discount_type` ENUM('fixed','percentage') DEFAULT 'fixed',
  `discount_value` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `discount_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `tax_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `total` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `loyalty_points_used` INT NOT NULL DEFAULT 0,
  `loyalty_discount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `loyalty_points_earned` INT NOT NULL DEFAULT 0,
  `payment_method` ENUM('cash','visa','wallet','split') DEFAULT 'cash',
  `cash_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `visa_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `wallet_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `change_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `status` ENUM('completed','held','refunded','partial_refund') DEFAULT 'completed',
  `notes` TEXT,
  `sale_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sales_invoice` (`invoice_number`),
  KEY `idx_sales_customer` (`customer_id`),
  KEY `idx_sales_user` (`user_id`),
  KEY `idx_sales_date` (`sale_date`),
  KEY `idx_sales_status` (`status`),
  FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `sales` (`id`, `invoice_number`, `customer_id`, `user_id`, `subtotal`, `discount_type`, `discount_value`, `discount_amount`, `tax_rate`, `tax_amount`, `total`, `payment_method`, `cash_amount`, `change_amount`, `loyalty_points_earned`, `status`, `sale_date`) VALUES
(1,  'INV-20250601-0001', 1,    1,  505.000, 'fixed',      0.000,  0.000, 15.00,  75.750,  580.750, 'visa',     0.000,   0.000,  58,  'completed', '2025-06-01 10:30:00'),
(2,  'INV-20250615-0001', 2,    1,  340.000, 'percentage', 5.000, 17.000, 15.00,  48.450,  371.450, 'cash',   400.000,  28.550,  37,  'completed', '2025-06-15 12:00:00'),
(3,  'INV-20250701-0001', 3,    1, 1100.000, 'fixed',      0.000,  0.000, 15.00, 165.000, 1265.000, 'visa',     0.000,   0.000, 127,  'completed', '2025-07-01 11:00:00'),
(4,  'INV-20250720-0001', NULL, 1,   90.000, 'fixed',      0.000,  0.000, 15.00,  13.500,  103.500, 'cash',   110.000,   6.500,  10,  'completed', '2025-07-20 09:30:00'),
(5,  'INV-20250801-0001', 4,    1,  262.000, 'fixed',      0.000,  0.000, 15.00,  39.300,  301.300, 'wallet',   0.000,   0.000,  30,  'completed', '2025-08-01 14:00:00'),
(6,  'INV-20260101-0001', 6,    1, 1390.000, 'percentage', 5.000, 69.500, 15.00, 198.075, 1518.575, 'visa',     0.000,   0.000, 152,  'completed', '2026-01-01 11:00:00'),
(7,  'INV-20260201-0001', 5,    1,  430.000, 'fixed',      0.000,  0.000, 15.00,  64.500,  494.500, 'cash',   500.000,   5.500,  49,  'completed', '2026-02-01 10:00:00'),
(8,  'INV-20260301-0001', 3,    1,  850.000, 'fixed',     50.000, 50.000, 15.00, 120.000,  920.000, 'visa',     0.000,   0.000,  92,  'completed', '2026-03-01 13:00:00'),
(9,  'INV-20260601-0001', 1,    1,  525.000, 'fixed',      0.000,  0.000, 15.00,  78.750,  603.750, 'split',    0.000,   0.000,  60,  'completed', '2026-06-01 10:00:00'),
(10, 'INV-20260610-0001', 2,    1,  320.000, 'percentage', 5.000, 16.000, 15.00,  45.600,  349.600, 'cash',   350.000,   0.400,  35,  'completed', '2026-06-10 14:00:00'),
(11, 'INV-20260620-0001', 6,    1, 1100.000, 'fixed',      0.000,  0.000, 15.00, 165.000, 1265.000, 'visa',     0.000,   0.000, 127,  'completed', '2026-06-20 11:30:00'),
(12, 'INV-20260625-0001', NULL, 1,  120.000, 'fixed',      0.000,  0.000, 15.00,  18.000,  138.000, 'cash',   140.000,   2.000,  14,  'completed', '2026-06-25 09:00:00'),
(13, 'INV-20260701-0001', 8,    1,  319.000, 'fixed',      0.000,  0.000, 15.00,  47.850,  366.850, 'visa',     0.000,   0.000,  37,  'completed', '2026-07-01 12:00:00'),
(14, 'INV-20260710-0001', 5,    1,  475.000, 'percentage', 5.000, 23.750, 15.00,  67.688,  518.938, 'visa',     0.000,   0.000,  52,  'completed', '2026-07-10 10:30:00'),
(15, 'INV-20260720-0001', 3,    1,  850.000, 'fixed',      0.000,  0.000, 15.00, 127.500,  977.500, 'visa',     0.000,   0.000,  98,  'completed', '2026-07-20 11:00:00'),
(16, 'INV-20260725-0001', 10,   1,  107.000, 'fixed',      0.000,  0.000, 15.00,  16.050,  123.050, 'cash',   130.000,   6.950,  12,  'completed', '2026-07-25 09:30:00'),
(17, 'INV-20260801-0001', 7,    1,  140.000, 'fixed',      0.000,  0.000, 15.00,  21.000,  161.000, 'cash',   170.000,   9.000,  16,  'completed', '2026-08-01 10:00:00'),
(18, 'INV-20260802-0001', 9,    1,  420.000, 'fixed',      0.000,  0.000, 15.00,  63.000,  483.000, 'visa',     0.000,   0.000,  48,  'completed', '2026-08-02 13:00:00'),
(19, 'INV-20260803-0001', 6,    1, 1530.000, 'percentage', 5.000, 76.500, 15.00, 218.475, 1671.975, 'visa',     0.000,   0.000, 167,  'completed', '2026-08-03 10:00:00'),
(20, 'INV-20260803-0002', NULL, 1,  160.000, 'fixed',      0.000,  0.000, 15.00,  24.000,  184.000, 'cash',   200.000,  16.000,  18,  'completed', '2026-08-03 15:00:00');

-- =============================================
-- SALE ITEMS
-- =============================================
CREATE TABLE `sale_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sale_id` INT UNSIGNED NOT NULL,
  `medicine_id` INT UNSIGNED NOT NULL,
  `batch_id` INT UNSIGNED,
  `quantity` INT NOT NULL,
  `unit_price` DECIMAL(10,3) NOT NULL,
  `discount_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `subtotal` DECIMAL(12,3) NOT NULL,
  `returned_quantity` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_sale_items_sale` (`sale_id`),
  KEY `idx_sale_items_medicine` (`medicine_id`),
  KEY `idx_sale_items_batch` (`batch_id`),
  FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`),
  FOREIGN KEY (`batch_id`) REFERENCES `medicine_batches`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `sale_items` (`id`, `sale_id`, `medicine_id`, `batch_id`, `quantity`, `unit_price`, `discount_amount`, `subtotal`) VALUES
-- Sale 1: Tote bag + Necklace + Scarf
(1,  1,  1,  1,  1, 295.000, 0.000, 295.000),
(2,  1,  9,  9,  2,  55.000, 0.000, 110.000),
(3,  1, 11, 11,  1,  65.000, 0.000,  65.000),
(4,  1, 16, 16,  1,  25.000, 0.000,  25.000),
-- Sale 2: Pandora ring + Crystal earrings + hair clips
(5,  2,  8,  8,  1, 230.000, 0.000, 230.000),
(6,  2,  7,  7,  1, 285.000, 0.000, 285.000),
-- Sale 3: Michael Kors bag + MK Watch (big sale)
(7,  3,  3,  3,  1, 850.000, 0.000, 850.000),
(8,  3, 26, 26,  1,1100.000, 0.000,1100.000),
-- Sale 4: Scarves (walk-in)
(9,  4, 13, 13,  1,  55.000, 0.000,  55.000),
(10, 4, 14, 14,  1,  90.000, 0.000,  90.000),
-- Sale 5: Swarovski earrings + makeup brushes
(11, 5,  7,  7,  1, 285.000, 0.000, 285.000),
-- Sale 6: Pandora bracelet + Ray-Ban + Guess watch
(12, 6, 32, 32,  1, 290.000, 0.000, 290.000),
(13, 6, 23, 23,  1, 390.000, 0.000, 390.000),
(14, 6, 27, 27,  1, 430.000, 0.000, 430.000),
-- Sale 7: Zara bag + wallet
(15, 7,  2,  2,  1, 210.000, 0.000, 210.000),
(16, 7, 28, 28,  1, 115.000, 0.000, 115.000),
(17, 7, 30, 30,  1,  65.000, 0.000,  65.000),
-- Sale 8: Michael Kors bag
(18, 8,  3,  3,  1, 850.000, 0.000, 850.000),
-- Sale 9: Hair straightener + clutch + perfume
(19, 9, 37, 37,  1, 140.000, 0.000, 140.000),
(20, 9,  4,  4,  1, 165.000, 0.000, 165.000),
(21, 9, 31, 31,  1, 145.000, 0.000, 145.000),
-- Sale 10: Guess sunglasses + scrunchies + hair clips
(22,10, 24, 24,  1, 175.000, 0.000, 175.000),
(23,10, 16, 16,  3,  25.000, 0.000,  75.000),
(24,10, 15, 15,  2,  35.000, 0.000,  70.000),
-- Sale 11: MK Watch + Pandora necklace
(25,11, 26, 26,  1,1100.000, 0.000,1100.000),
-- Sale 12: Phone cases (walk-in)
(26,12, 35, 35,  2,  35.000, 0.000,  70.000),
(27,12, 36, 36,  1,  35.000, 0.000,  35.000),
-- Sale 13: Makeup set + mirror + lash kit
(28,13, 19, 19,  1,  89.000, 0.000,  89.000),
(29,13, 20, 20,  1,  75.000, 0.000,  75.000),
(30,13, 22, 22,  1,  55.000, 0.000,  55.000),
-- Sale 14: Swarovski bangle + pendant necklace
(31,14, 33, 33,  1, 330.000, 0.000, 330.000),
(32,14, 10, 10,  1, 360.000, 0.000, 360.000),
-- Sale 15: MK Bag + Watch
(33,15,  3,  3,  1, 850.000, 0.000, 850.000),
-- Sale 16: Hair care + body mist
(34,16, 30, 30,  1,  65.000, 0.000,  65.000),
(35,16, 18, 18,  1,  28.000, 0.000,  28.000),
-- Sale 17: Curling wand
(36,17, 38, 38,  1, 160.000, 0.000, 160.000),
-- Sale 18: Pandora ring + bracelet + earrings
(37,18,  6,  6,  1, 420.000, 0.000, 420.000),
-- Sale 19: Ray-Ban + Guess watch + MK bag (VIP customer)
(38,19, 23, 23,  1, 390.000, 0.000, 390.000),
(39,19, 27, 27,  1, 430.000, 0.000, 430.000),
(40,19,  1,  1,  1, 295.000, 0.000, 295.000),
-- Sale 20: Shawls + scarf (walk-in)
(41,20, 14, 14,  1,  90.000, 0.000,  90.000),
(42,20, 13, 13,  1,  55.000, 0.000,  55.000),
(43,20, 16, 16,  1,  25.000, 0.000,  25.000);

-- =============================================
-- HELD INVOICES
-- =============================================
CREATE TABLE `held_invoices` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED,
  `customer_id` INT UNSIGNED,
  `label` VARCHAR(100),
  `cart_data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_held_user` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- RETURNS
-- =============================================
CREATE TABLE `returns` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `return_number` VARCHAR(50) NOT NULL,
  `type` ENUM('sale','purchase') NOT NULL,
  `reference_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED,
  `supplier_id` INT UNSIGNED,
  `customer_id` INT UNSIGNED,
  `total_amount` DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  `reason` TEXT,
  `status` ENUM('pending','completed','cancelled') DEFAULT 'completed',
  `payment_method` ENUM('cash','visa','wallet','bank_transfer','mixed') DEFAULT NULL,
  `cash_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `visa_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `wallet_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `bank_transfer_amount` DECIMAL(10,3) NOT NULL DEFAULT 0.000,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_returns_number` (`return_number`),
  KEY `idx_returns_type` (`type`, `reference_id`),
  KEY `idx_returns_user` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- RETURN ITEMS
-- =============================================
CREATE TABLE `return_items` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `return_id` INT UNSIGNED NOT NULL,
  `medicine_id` INT UNSIGNED NOT NULL,
  `batch_id` INT UNSIGNED,
  `quantity` INT NOT NULL,
  `unit_price` DECIMAL(10,3) NOT NULL,
  `subtotal` DECIMAL(12,3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_return_items_return` (`return_id`),
  KEY `idx_return_items_medicine` (`medicine_id`),
  FOREIGN KEY (`return_id`) REFERENCES `returns`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`),
  FOREIGN KEY (`batch_id`) REFERENCES `medicine_batches`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- INVENTORY ADJUSTMENTS
-- =============================================
CREATE TABLE `inventory_adjustments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `reference_number` VARCHAR(50) NOT NULL,
  `medicine_id` INT UNSIGNED NOT NULL,
  `batch_id` INT UNSIGNED,
  `user_id` INT UNSIGNED,
  `type` ENUM('add','remove','correction') NOT NULL,
  `quantity_before` INT NOT NULL,
  `quantity_change` INT NOT NULL,
  `quantity_after` INT NOT NULL,
  `reason` VARCHAR(255),
  `notes` TEXT,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_adj_medicine` (`medicine_id`),
  KEY `idx_adj_batch` (`batch_id`),
  KEY `idx_adj_user` (`user_id`),
  KEY `idx_adj_created` (`created_at`),
  FOREIGN KEY (`medicine_id`) REFERENCES `medicines`(`id`),
  FOREIGN KEY (`batch_id`) REFERENCES `medicine_batches`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- NOTIFICATIONS
-- =============================================
CREATE TABLE `notifications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `type` ENUM('low_stock','purchase_due','customer_due','system') NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `message` TEXT NOT NULL,
  `model` VARCHAR(50),
  `model_id` INT UNSIGNED,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `read_by` INT UNSIGNED,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_notifications_type` (`type`),
  KEY `idx_notifications_read` (`is_read`),
  KEY `idx_notifications_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `notifications` (`id`, `type`, `title`, `message`, `model`, `model_id`, `is_read`, `created_at`) VALUES
(1, 'low_stock', 'Low Stock Alert',       'Michael Kors Jet Set Tote has only 4 units remaining — reorder soon',   'medicine', 3,  0, NOW() - INTERVAL 1 DAY),
(2, 'low_stock', 'Low Stock Alert',       'Michael Kors Lexington Watch is down to 3 units',                       'medicine', 26, 0, NOW() - INTERVAL 2 DAY),
(3, 'system',    'New Purchase Received', 'Purchase PO-20260601-0001 received from Trend Suppliers Arabia',         'purchase', 6,  1, NOW() - INTERVAL 3 DAY),
(4, 'system',    'Daily Target Reached',  'Today''s sales exceeded the daily target — great performance!',          NULL, NULL,    1, NOW() - INTERVAL 1 DAY),
(5, 'low_stock', 'Low Stock Alert',       'Ray-Ban Cat Eye Sunglasses has only 5 units left',                      'medicine', 23, 0, NOW()),
(6, 'purchase_due','Payment Due',         'Purchase PO-20250401-0001 has an outstanding balance of SAR 1,026',     'purchase', 3,  0, NOW() - INTERVAL 4 DAY);

-- =============================================
-- DRUG SYNC LOGS (schema compat)
-- =============================================
CREATE TABLE `drug_sync_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `provider` VARCHAR(50) NOT NULL DEFAULT 'saudi_rsd',
  `sync_type` ENUM('full','incremental','single') NOT NULL DEFAULT 'full',
  `status` ENUM('running','completed','failed') NOT NULL DEFAULT 'running',
  `medicines_checked` INT UNSIGNED NOT NULL DEFAULT 0,
  `medicines_updated` INT UNSIGNED NOT NULL DEFAULT 0,
  `medicines_failed` INT UNSIGNED NOT NULL DEFAULT 0,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `error_message` TEXT DEFAULT NULL,
  `triggered_by` INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_started_at` (`started_at`),
  KEY `idx_status` (`status`),
  FOREIGN KEY (`triggered_by`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- PERFORMANCE INDEXES
-- =============================================
ALTER TABLE `medicine_batches` ADD INDEX `idx_batch_fifo` (`medicine_id`, `id`);
ALTER TABLE `sale_items` ADD INDEX `idx_sale_items_medicine_date` (`medicine_id`);

SET FOREIGN_KEY_CHECKS = 1;

SELECT 'wave_db (women''s accessories) imported successfully!' AS status;
