SET NAMES utf8mb4;

SET @column_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'phone'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `phone` varchar(40) NOT NULL DEFAULT '''' COMMENT ''电话号'' AFTER `area`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @column_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'email'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `email` varchar(120) NOT NULL DEFAULT '''' COMMENT ''邮箱'' AFTER `phone`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND INDEX_NAME = 'idx_phone'
);
SET @sql = IF(
  @index_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD KEY `idx_phone` (`phone`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @index_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND INDEX_NAME = 'idx_email'
);
SET @sql = IF(
  @index_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD KEY `idx_email` (`email`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
