SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_shop_manager` (
  `id` int unsigned NOT NULL AUTO_INCREMENT COMMENT '管理者ID',
  `name` varchar(80) NOT NULL DEFAULT '' COMMENT '名字',
  `mobile` varchar(30) NOT NULL DEFAULT '' COMMENT '电话',
  `password` varchar(255) NOT NULL DEFAULT '' COMMENT '密码',
  `create_time` int unsigned NOT NULL DEFAULT 0 COMMENT '创建时间',
  `update_time` int unsigned NOT NULL DEFAULT 0 COMMENT '更新时间',
  `delete_time` int unsigned DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_mobile` (`mobile`),
  KEY `idx_delete_time` (`delete_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 商铺管理者';

SET @column_exists = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_shop'
    AND COLUMN_NAME = 'manager_id'
);
SET @sql = IF(
  @column_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD COLUMN `manager_id` int unsigned NOT NULL DEFAULT 0 COMMENT ''商铺管理者ID'' AFTER `id`',
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
    AND INDEX_NAME = 'idx_manager_id'
);
SET @sql = IF(
  @index_exists = 0,
  'ALTER TABLE `la_cbk_shop` ADD KEY `idx_manager_id` (`manager_id`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
