CREATE TABLE IF NOT EXISTS `la_cbk_cast_favorite` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL DEFAULT 0,
  `cast_id` int unsigned NOT NULL DEFAULT 0,
  `create_time` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_cast` (`user_id`,`cast_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_cast_id` (`cast_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA Cast收藏';
