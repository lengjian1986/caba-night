SET NAMES utf8mb4;

SET @column_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop_review'
    AND COLUMN_NAME = 'cast_id'
);
SET @sql := IF(@column_exists = 0,
  'ALTER TABLE `la_cbk_shop_review` ADD COLUMN `cast_id` int unsigned NOT NULL DEFAULT 0 COMMENT ''Cast ID'' AFTER `shop_id`, ADD KEY `idx_cast_status` (`cast_id`,`status`)',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
