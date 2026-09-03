SET NAMES utf8mb4;

SET @logo_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'logo_image'
);

SET @sql := IF(
  @logo_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `logo_image` varchar(500) NOT NULL DEFAULT '''' COMMENT ''店铺 Logo'' AFTER `package_sets`',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @images_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'shop_images'
);

SET @sql := IF(
  @images_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `shop_images` text COMMENT ''店铺照片 JSON'' AFTER `logo_image`',
  'SELECT 1'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
