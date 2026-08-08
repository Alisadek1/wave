-- Wave Store — Settings Update
-- Run this once against your database to rename the store from PharmaCare to Wave

UPDATE `settings` SET `value` = 'Wave'                        WHERE `key` = 'pharmacy_name';
UPDATE `settings` SET `value` = 'ويف'                         WHERE `key` = 'pharmacy_name_ar';
UPDATE `settings` SET `value` = 'Thank you for shopping with us!' WHERE `key` = 'receipt_footer';
