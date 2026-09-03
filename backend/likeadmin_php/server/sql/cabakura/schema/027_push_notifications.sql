SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_push_notification` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL DEFAULT '',
  `content` text NOT NULL,
  `link` varchar(500) NOT NULL DEFAULT '',
  `mode` varchar(20) NOT NULL DEFAULT 'immediate' COMMENT 'immediate/scheduled',
  `scheduled_at` int unsigned NOT NULL DEFAULT 0,
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT 'pending/sent',
  `sent_at` int unsigned NOT NULL DEFAULT 0,
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_status_schedule` (`status`,`scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='プッシュ通知';
