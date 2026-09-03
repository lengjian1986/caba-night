-- CABAKURA P0 首批业务表
-- 金额字段使用日元整数。时间字段兼容 LikeAdmin 现有 int timestamp 风格。

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_shop` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL DEFAULT '' COMMENT '店铺名',
  `kana` varchar(120) NOT NULL DEFAULT '' COMMENT '店铺假名',
  `area` varchar(120) NOT NULL DEFAULT '' COMMENT '区域',
  `phone` varchar(40) NOT NULL DEFAULT '' COMMENT '电话号',
  `email` varchar(120) NOT NULL DEFAULT '' COMMENT '邮箱',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '地址',
  `station` varchar(120) NOT NULL DEFAULT '' COMMENT '最近车站',
  `business_hours` varchar(80) NOT NULL DEFAULT '' COMMENT '营业时间',
  `price_range` varchar(120) NOT NULL DEFAULT '' COMMENT '价格区间',
  `description` text COMMENT '店铺说明',
  `keywords` varchar(500) NOT NULL DEFAULT '' COMMENT '检索关键字，空格分隔',
  `tags` varchar(500) NOT NULL DEFAULT '' COMMENT '标签 JSON',
  `package_sets` text COMMENT '套餐 Set JSON',
  `logo_image` varchar(500) NOT NULL DEFAULT '' COMMENT '店铺 Logo',
  `shop_images` text COMMENT '店铺照片 JSON',
  `license_no` varchar(120) NOT NULL DEFAULT '' COMMENT '营业执照/许可编号',
  `license_holder_name` varchar(120) NOT NULL DEFAULT '' COMMENT '经营主体',
  `license_expires_at` varchar(20) NOT NULL DEFAULT '' COMMENT '许可有效期',
  `license_file_name` varchar(255) NOT NULL DEFAULT '' COMMENT '执照文件名',
  `license_files` text COMMENT '许可证件 JSON',
  `review_status` varchar(40) NOT NULL DEFAULT 'draft' COMMENT '审核状态',
  `business_status` varchar(40) NOT NULL DEFAULT '休息中' COMMENT '营业状态',
  `is_recommended` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '人気店舗表示',
  `booking_enabled` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '是否开放预约',
  `submitted_at` int unsigned NOT NULL DEFAULT 0 COMMENT '提交审核时间',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_review_status` (`review_status`),
  KEY `idx_area` (`area`),
  KEY `idx_phone` (`phone`),
  KEY `idx_email` (`email`),
  KEY `idx_is_recommended` (`is_recommended`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 店铺';

CREATE TABLE IF NOT EXISTS `la_cbk_member` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_no` varchar(40) NOT NULL DEFAULT '' COMMENT '会员编号',
  `nickname` varchar(80) NOT NULL DEFAULT '' COMMENT '昵称',
  `real_name` varchar(80) NOT NULL DEFAULT '' COMMENT '真实姓名',
  `mobile` varchar(40) NOT NULL DEFAULT '' COMMENT '手机号',
  `level_name` varchar(60) NOT NULL DEFAULT '' COMMENT '会员等级',
  `identity_status` varchar(40) NOT NULL DEFAULT 'not_started' COMMENT '身份认证状态',
  `identity_image` varchar(500) NOT NULL DEFAULT '' COMMENT '证件图片',
  `status` varchar(40) NOT NULL DEFAULT 'normal' COMMENT '会员状态',
  `wallet_balance` int unsigned NOT NULL DEFAULT 0 COMMENT '钱包余额（日元）',
  `order_count` int unsigned NOT NULL DEFAULT 0 COMMENT '预约次数',
  `favorite_count` int unsigned NOT NULL DEFAULT 0 COMMENT '收藏数',
  `review_count` int unsigned NOT NULL DEFAULT 0 COMMENT '评价数',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_no` (`member_no`),
  KEY `idx_mobile` (`mobile`),
  KEY `idx_identity_status` (`identity_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 会员';

CREATE TABLE IF NOT EXISTS `la_cbk_shop_review_log` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` int unsigned NOT NULL DEFAULT 0 COMMENT '店铺ID',
  `action` varchar(80) NOT NULL DEFAULT '' COMMENT '审核动作',
  `operator` varchar(80) NOT NULL DEFAULT '' COMMENT '操作人',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_shop_action_time` (`shop_id`, `action`, `create_time`),
  KEY `idx_shop_id` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 店铺审核记录';

CREATE TABLE IF NOT EXISTS `la_cbk_order` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `order_no` varchar(80) NOT NULL DEFAULT '' COMMENT '订单号',
  `member_name` varchar(80) NOT NULL DEFAULT '' COMMENT '会员名',
  `shop_name` varchar(120) NOT NULL DEFAULT '' COMMENT '店铺名',
  `cast_name` varchar(120) NOT NULL DEFAULT '' COMMENT 'Cast名',
  `visit_time` int unsigned NOT NULL DEFAULT 0 COMMENT '来店时间',
  `people_count` int unsigned NOT NULL DEFAULT 1 COMMENT '人数',
  `amount` int unsigned NOT NULL DEFAULT 0 COMMENT '支付金额（日元）',
  `status` varchar(40) NOT NULL DEFAULT 'requesting' COMMENT '订单状态',
  `pay_status_text` varchar(40) NOT NULL DEFAULT '' COMMENT '支付状态展示',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_status` (`status`),
  KEY `idx_visit_time` (`visit_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 预约订单';

CREATE TABLE IF NOT EXISTS `la_cbk_support_ticket` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ticket_no` varchar(80) NOT NULL DEFAULT '' COMMENT '工单号',
  `category` varchar(80) NOT NULL DEFAULT '' COMMENT '分类',
  `member_name` varchar(80) NOT NULL DEFAULT '' COMMENT '会员名',
  `order_no` varchar(80) NOT NULL DEFAULT '' COMMENT '关联订单号',
  `shop_name` varchar(120) NOT NULL DEFAULT '' COMMENT '店铺名',
  `status` varchar(40) NOT NULL DEFAULT 'open' COMMENT '工单状态',
  `last_message` varchar(500) NOT NULL DEFAULT '' COMMENT '最后消息',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ticket_no` (`ticket_no`),
  KEY `idx_status` (`status`),
  KEY `idx_order_no` (`order_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 客服工单';

INSERT INTO `la_cbk_shop`
(`id`, `name`, `kana`, `area`, `address`, `station`, `business_hours`, `price_range`, `tags`, `package_sets`, `logo_image`, `shop_images`, `license_no`, `license_holder_name`, `license_expires_at`, `license_file_name`, `license_files`, `review_status`, `business_status`, `booking_enabled`, `submitted_at`, `create_time`, `update_time`)
VALUES
(1, 'LUXE TOKYO', 'リュクス トウキョウ', '新宿・歌舞伎町', '東京都新宿区歌舞伎町1-1-1', '新宿駅 徒歩3分', '20:00-LAST', '¥10,000~¥18,000 / 60分', '["高級感","明朗会計","当日予約OK"]', '[{"name":"Standard Set","duration_minutes":60,"price":10000,"description":"基本料金 60分"},{"name":"Premium Set","duration_minutes":90,"price":18000,"description":"ゆったり利用できる 90分"}]', '', '[]', 'TOKYO-2026-0018', '株式会社 LUXE', '2027-08-31', 'business-license-luxe.pdf', '["business-license-luxe.pdf"]', 'reviewing', '営業中', 0, UNIX_TIMESTAMP('2026-08-05 01:40:00'), UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, 'Lounge Belle', 'ラウンジ ベル', '銀座', '東京都中央区銀座1-2-3', '銀座駅 徒歩4分', '20:00-LAST', '¥6,000~¥12,000 / 60分', '["落ち着いた上質空間","初回歓迎"]', '[{"name":"Table Set","duration_minutes":60,"price":6000,"description":"初回にも使いやすい基本 Set"}]', '', '[]', 'TOKYO-2026-0007', '株式会社 Belle', '2027-07-31', 'business-license-belle.pdf', '["business-license-belle.pdf"]', 'approved', '営業中', 1, UNIX_TIMESTAMP('2026-07-28 06:10:00'), UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`),
`kana` = VALUES(`kana`),
`area` = VALUES(`area`),
`address` = VALUES(`address`),
`station` = VALUES(`station`),
`business_hours` = VALUES(`business_hours`),
`price_range` = VALUES(`price_range`),
`tags` = VALUES(`tags`),
`package_sets` = VALUES(`package_sets`),
`logo_image` = VALUES(`logo_image`),
`shop_images` = VALUES(`shop_images`),
`license_no` = VALUES(`license_no`),
`license_holder_name` = VALUES(`license_holder_name`),
`license_expires_at` = VALUES(`license_expires_at`),
`license_file_name` = VALUES(`license_file_name`),
`license_files` = VALUES(`license_files`),
`review_status` = VALUES(`review_status`),
`business_status` = VALUES(`business_status`),
`booking_enabled` = VALUES(`booking_enabled`),
`submitted_at` = VALUES(`submitted_at`),
`update_time` = VALUES(`update_time`);

INSERT INTO `la_cbk_member`
(`id`, `member_no`, `nickname`, `real_name`, `mobile`, `level_name`, `identity_status`, `identity_image`, `status`, `wallet_balance`, `order_count`, `favorite_count`, `review_count`, `create_time`, `update_time`)
VALUES
(1, '0001234', '山田 太郎', '山田 太郎', '090-1234-5678', '一般会員', 'approved', '', 'normal', 12800, 24, 18, 36, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()),
(2, '0001235', '佐藤 健', '佐藤 健', '080-2222-3333', '一般会員', 'reviewing', '', 'normal', 0, 3, 5, 1, UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
`nickname` = VALUES(`nickname`),
`real_name` = VALUES(`real_name`),
`mobile` = VALUES(`mobile`),
`level_name` = VALUES(`level_name`),
`identity_status` = VALUES(`identity_status`),
`identity_image` = VALUES(`identity_image`),
`status` = VALUES(`status`),
`wallet_balance` = VALUES(`wallet_balance`),
`order_count` = VALUES(`order_count`),
`favorite_count` = VALUES(`favorite_count`),
`review_count` = VALUES(`review_count`),
`update_time` = VALUES(`update_time`);

INSERT IGNORE INTO `la_cbk_shop_review_log`
(`shop_id`, `action`, `operator`, `remark`, `create_time`)
VALUES
(1, '提交审核', '店铺管理员', '新店铺资料提交', UNIX_TIMESTAMP('2026-08-05 01:40:00')),
(1, '进入审核', '平台运营', '资料完整，开始审核', UNIX_TIMESTAMP('2026-08-05 02:12:00'));

INSERT INTO `la_cbk_support_ticket`
(`id`, `ticket_no`, `category`, `member_name`, `order_no`, `shop_name`, `status`, `last_message`, `create_time`, `update_time`)
VALUES
(1, 'SUP-20260805-0001', '预约について', '山田 太郎', 'CBK-0731-0812', 'LUXE TOKYO', 'pending_operator', '来店時間を15分ほど遅らせることは可能でしょうか？', UNIX_TIMESTAMP(), UNIX_TIMESTAMP('2026-08-05 01:41:00')),
(2, 'SUP-20260805-0002', '支払い・領収書', '佐藤 健', 'CG-20260721-0184', 'Lounge Belle', 'open', '領収書PDFを再発行したいです。', UNIX_TIMESTAMP(), UNIX_TIMESTAMP('2026-08-05 02:05:00'))
ON DUPLICATE KEY UPDATE
`category` = VALUES(`category`),
`member_name` = VALUES(`member_name`),
`order_no` = VALUES(`order_no`),
`shop_name` = VALUES(`shop_name`),
`status` = VALUES(`status`),
`last_message` = VALUES(`last_message`),
`update_time` = VALUES(`update_time`);
