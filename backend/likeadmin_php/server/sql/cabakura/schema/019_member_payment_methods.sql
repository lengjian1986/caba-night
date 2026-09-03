SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_member_payment_method` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL DEFAULT 0 COMMENT 'ユーザーID',
  `provider` varchar(30) NOT NULL DEFAULT 'card' COMMENT '決済プロバイダ',
  `provider_method_id` varchar(191) NOT NULL DEFAULT '' COMMENT '決済プロバイダ側のID',
  `brand` varchar(30) NOT NULL DEFAULT '' COMMENT 'カードブランド',
  `last4` varchar(4) NOT NULL DEFAULT '' COMMENT 'カード下4桁',
  `expiry` varchar(7) NOT NULL DEFAULT '' COMMENT '有効期限',
  `holder_name` varchar(120) NOT NULL DEFAULT '' COMMENT 'カード名義',
  `is_default` tinyint unsigned NOT NULL DEFAULT 0 COMMENT 'デフォルト',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_provider_method_id` (`provider_method_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 会員支払い方法';
