SET NAMES utf8mb4;

SET @column_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_member'
    AND COLUMN_NAME = 'identity_image'
);

SET @sql := IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_member` ADD COLUMN `identity_image` varchar(500) NOT NULL DEFAULT '''' COMMENT ''证件图片'' AFTER `identity_status`',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
