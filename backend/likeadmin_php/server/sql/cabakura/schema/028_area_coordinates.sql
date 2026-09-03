SET NAMES utf8mb4;

SET @has_latitude := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'la_cbk_area' AND COLUMN_NAME = 'latitude'
);
SET @sql := IF(@has_latitude = 0,
    'ALTER TABLE `la_cbk_area` ADD COLUMN `latitude` decimal(10,7) NOT NULL DEFAULT 0 COMMENT ''緯度'' AFTER `city`',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_longitude := (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'la_cbk_area' AND COLUMN_NAME = 'longitude'
);
SET @sql := IF(@has_longitude = 0,
    'ALTER TABLE `la_cbk_area` ADD COLUMN `longitude` decimal(10,7) NOT NULL DEFAULT 0 COMMENT ''経度'' AFTER `latitude`',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE `la_cbk_area` SET `latitude` = 35.6762000, `longitude` = 139.6503000 WHERE `name` = '東京都';
UPDATE `la_cbk_area` SET `latitude` = 34.6937000, `longitude` = 135.5023000 WHERE `name` = '大阪府';
UPDATE `la_cbk_area` SET `latitude` = 35.0116000, `longitude` = 135.7681000 WHERE `name` = '京都府';
UPDATE `la_cbk_area` SET `latitude` = 35.1815000, `longitude` = 136.9066000 WHERE `name` = '愛知県';
UPDATE `la_cbk_area` SET `latitude` = 35.6074000, `longitude` = 140.1065000 WHERE `name` = '千葉県';
UPDATE `la_cbk_area` SET `latitude` = 35.4437000, `longitude` = 139.6380000 WHERE `name` = '神奈川県';
