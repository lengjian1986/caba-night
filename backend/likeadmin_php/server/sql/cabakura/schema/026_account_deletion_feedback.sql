SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_account_deletion_feedback` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL DEFAULT 0,
  `reason` varchar(100) NOT NULL DEFAULT '' COMMENT '注销理由',
  `reuse_app` varchar(20) NOT NULL DEFAULT '' COMMENT '今后是否继续使用类似APP',
  `feedback` text COMMENT '用户意见',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='アカウント削除アンケート';
