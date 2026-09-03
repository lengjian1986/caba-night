SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_area` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL DEFAULT '' COMMENT 'エリア名',
  `prefecture` varchar(80) NOT NULL DEFAULT '' COMMENT '都道府県',
  `city` varchar(80) NOT NULL DEFAULT '' COMMENT '市区町村',
  `sort` int unsigned NOT NULL DEFAULT 0 COMMENT '表示順',
  `is_show` tinyint unsigned NOT NULL DEFAULT 1 COMMENT '表示',
  `is_recommended` tinyint unsigned NOT NULL DEFAULT 0 COMMENT 'おすすめ表示',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_name` (`name`),
  KEY `idx_name` (`name`),
  KEY `idx_is_show` (`is_show`),
  KEY `idx_is_recommended` (`is_recommended`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA エリア';

SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_cbk_area`
(`name`, `prefecture`, `city`, `sort`, `is_show`, `is_recommended`, `create_time`, `update_time`)
VALUES
('銀座', '東京都', '中央区', 100, 1, 1, @now, @now),
('六本木', '東京都', '港区', 90, 1, 1, @now, @now),
('新宿・歌舞伎町', '東京都', '新宿区', 80, 1, 1, @now, @now),
('恵比寿', '東京都', '渋谷区', 70, 1, 0, @now, @now),
('梅田', '大阪府', '大阪市北区', 60, 1, 1, @now, @now),
('北新地', '大阪府', '大阪市北区', 50, 1, 1, @now, @now)
ON DUPLICATE KEY UPDATE
  `prefecture` = VALUES(`prefecture`),
  `city` = VALUES(`city`),
  `sort` = VALUES(`sort`),
  `is_show` = VALUES(`is_show`),
  `is_recommended` = VALUES(`is_recommended`),
  `update_time` = VALUES(`update_time`);
