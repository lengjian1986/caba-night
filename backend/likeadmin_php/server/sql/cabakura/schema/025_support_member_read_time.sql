SET NAMES utf8mb4;
SET @db = DATABASE();
SET @column = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=@db AND TABLE_NAME='la_cbk_support_ticket' AND COLUMN_NAME='member_read_time');
SET @sql = IF(@column=0, 'ALTER TABLE `la_cbk_support_ticket` ADD COLUMN `member_read_time` int unsigned NOT NULL DEFAULT 0 COMMENT ''会員最終既読時刻'' AFTER `update_time`', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
