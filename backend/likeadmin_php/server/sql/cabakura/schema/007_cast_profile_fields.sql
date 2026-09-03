SET NAMES utf8mb4;

SET @has_preferred_male_type = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_cast'
    AND COLUMN_NAME = 'preferred_male_type'
);
SET @sql = IF(@has_preferred_male_type = 0,
  'ALTER TABLE `la_cbk_cast` ADD COLUMN `preferred_male_type` varchar(255) NOT NULL DEFAULT '''' COMMENT ''喜欢男生类型'' AFTER `measurements`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_smoking_status = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_cast'
    AND COLUMN_NAME = 'smoking_status'
);
SET @sql = IF(@has_smoking_status = 0,
  'ALTER TABLE `la_cbk_cast` ADD COLUMN `smoking_status` varchar(40) NOT NULL DEFAULT ''unknown'' COMMENT ''抽烟状况'' AFTER `preferred_male_type`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_drinking_status = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_cast'
    AND COLUMN_NAME = 'drinking_status'
);
SET @sql = IF(@has_drinking_status = 0,
  'ALTER TABLE `la_cbk_cast` ADD COLUMN `drinking_status` varchar(40) NOT NULL DEFAULT ''unknown'' COMMENT ''喝酒状况'' AFTER `smoking_status`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
