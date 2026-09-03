SET NAMES utf8mb4;
SET @db = DATABASE();
SET @column = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='la_cbk_coupon' AND COLUMN_NAME='logo_image');
SET @sql = IF(@column=0, 'ALTER TABLE `la_cbk_coupon` ADD COLUMN `logo_image` varchar(500) NOT NULL DEFAULT '''' COMMENT ''クーポンロゴ'' AFTER `description`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
