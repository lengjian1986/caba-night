SET NAMES utf8mb4;
SET @db = DATABASE();
SET @coupon_column = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='la_cbk_coupon' AND COLUMN_NAME='validity_days');
SET @sql = IF(@coupon_column=0, 'ALTER TABLE `la_cbk_coupon` ADD COLUMN `validity_days` int unsigned NOT NULL DEFAULT 30 COMMENT ''取得後の有効日数'' AFTER `end_time`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @member_column = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='la_cbk_member_coupon' AND COLUMN_NAME='expire_time');
SET @sql = IF(@member_column=0, 'ALTER TABLE `la_cbk_member_coupon` ADD COLUMN `expire_time` int unsigned NOT NULL DEFAULT 0 COMMENT ''有効期限'' AFTER `received_time`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
