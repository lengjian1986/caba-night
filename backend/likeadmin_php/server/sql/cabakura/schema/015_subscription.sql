SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_subscription_plan` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL DEFAULT '' COMMENT 'Plan名',
  `price` int unsigned NOT NULL DEFAULT 0 COMMENT '价格（日元）',
  `duration_days` int unsigned NOT NULL DEFAULT 30 COMMENT '有效天数',
  `description` varchar(500) NOT NULL DEFAULT '' COMMENT '说明',
  `benefits` text COMMENT '权益 JSON',
  `is_enabled` tinyint unsigned NOT NULL DEFAULT 1 COMMENT '是否启用',
  `sort` int unsigned NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_enabled` (`is_enabled`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 订阅Plan';

CREATE TABLE IF NOT EXISTS `la_cbk_subscription` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int unsigned NOT NULL DEFAULT 0 COMMENT '会员ID',
  `member_no` varchar(40) NOT NULL DEFAULT '' COMMENT '会员编号',
  `nickname` varchar(80) NOT NULL DEFAULT '' COMMENT '昵称',
  `mobile` varchar(40) NOT NULL DEFAULT '' COMMENT '手机号',
  `plan_id` int unsigned NOT NULL DEFAULT 0 COMMENT 'Plan ID',
  `plan_name` varchar(120) NOT NULL DEFAULT '' COMMENT 'Plan名',
  `start_time` int unsigned NOT NULL DEFAULT 0 COMMENT '开始时间',
  `end_time` int unsigned NOT NULL DEFAULT 0 COMMENT '结束时间',
  `status` varchar(40) NOT NULL DEFAULT 'active' COMMENT '状态',
  `auto_renew` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '自动续费',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_member_no` (`member_no`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_status` (`status`),
  KEY `idx_end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 用户订阅';

CREATE TABLE IF NOT EXISTS `la_cbk_subscription_record` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `subscription_id` int unsigned NOT NULL DEFAULT 0 COMMENT '订阅ID',
  `member_id` int unsigned NOT NULL DEFAULT 0 COMMENT '会员ID',
  `member_no` varchar(40) NOT NULL DEFAULT '' COMMENT '会员编号',
  `nickname` varchar(80) NOT NULL DEFAULT '' COMMENT '昵称',
  `plan_id` int unsigned NOT NULL DEFAULT 0 COMMENT 'Plan ID',
  `plan_name` varchar(120) NOT NULL DEFAULT '' COMMENT 'Plan名',
  `amount` int unsigned NOT NULL DEFAULT 0 COMMENT '金额（日元）',
  `action` varchar(40) NOT NULL DEFAULT 'subscribe' COMMENT '动作',
  `pay_status` varchar(40) NOT NULL DEFAULT 'paid' COMMENT '支付状态',
  `transaction_no` varchar(120) NOT NULL DEFAULT '' COMMENT '交易号',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_subscription_id` (`subscription_id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_member_no` (`member_no`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_pay_status` (`pay_status`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 订阅记录';
