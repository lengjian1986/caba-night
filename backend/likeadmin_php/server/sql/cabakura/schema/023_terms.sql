SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_terms` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL DEFAULT '' COMMENT '条款名称',
  `title` varchar(255) NOT NULL DEFAULT '' COMMENT '主题',
  `content` longtext COMMENT '条款内容',
  `applies_to` varchar(80) NOT NULL DEFAULT 'all' COMMENT '应用的地方',
  `is_show` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '展示开关',
  `sort` int unsigned NOT NULL DEFAULT 0,
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_terms_show_sort` (`is_show`,`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 利用規約';
