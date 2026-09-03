SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_news` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `logo_image` varchar(500) NOT NULL DEFAULT '' COMMENT 'Logo图片',
  `title` varchar(255) NOT NULL DEFAULT '' COMMENT 'タイトル',
  `link` varchar(500) NOT NULL DEFAULT '' COMMENT 'リンク先',
  `content` text COMMENT '正文',
  `is_show` tinyint unsigned NOT NULL DEFAULT 1 COMMENT '是否展示',
  `sort` int unsigned NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_is_show` (`is_show`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA ニュース';
