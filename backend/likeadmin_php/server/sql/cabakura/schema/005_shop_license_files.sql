SET NAMES utf8mb4;

SET @column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'license_files'
);

SET @sql := IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `license_files` text COMMENT ''许可证件 JSON'' AFTER `license_file_name`',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `la_cbk_shop`
SET `license_files` = JSON_ARRAY(`license_file_name`)
WHERE (`license_files` IS NULL OR `license_files` = '')
  AND `license_file_name` <> '';
