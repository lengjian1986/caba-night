SET NAMES utf8mb4;

SET @db_name := DATABASE();
SET @column_exists := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = @db_name
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'keywords'
);
SET @sql := IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `keywords` varchar(500) NOT NULL DEFAULT '''' COMMENT ''检索关键字，空格分隔'' AFTER `description`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
