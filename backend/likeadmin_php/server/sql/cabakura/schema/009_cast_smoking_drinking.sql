SET NAMES utf8mb4;

SET @has_smoking_drinking = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_cast'
    AND COLUMN_NAME = 'smoking_drinking'
);
SET @sql = IF(@has_smoking_drinking = 0,
  'ALTER TABLE `la_cbk_cast` ADD COLUMN `smoking_drinking` varchar(80) NOT NULL DEFAULT '''' COMMENT ''抽烟喝酒'' AFTER `preferred_male_type`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
