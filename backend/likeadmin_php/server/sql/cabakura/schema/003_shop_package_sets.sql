SET NAMES utf8mb4;

SET @column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'package_sets'
);

SET @sql := IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `package_sets` text COMMENT ''套餐 Set JSON'' AFTER `tags`',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
