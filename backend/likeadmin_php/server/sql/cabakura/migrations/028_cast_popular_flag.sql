SET @column_exists := (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_cast'
    AND COLUMN_NAME = 'is_popular'
);
SET @sql := IF(@column_exists = 0,
  'ALTER TABLE `la_cbk_cast` ADD COLUMN `is_popular` tinyint unsigned NOT NULL DEFAULT 0 COMMENT ''人気表示'' AFTER `is_new`',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
