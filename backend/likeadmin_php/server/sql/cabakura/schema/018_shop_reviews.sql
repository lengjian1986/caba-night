CREATE TABLE IF NOT EXISTS `la_cbk_shop_review` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` int unsigned NOT NULL DEFAULT 0,
  `member_name` varchar(80) NOT NULL DEFAULT '',
  `rating` decimal(2,1) NOT NULL DEFAULT 0.0,
  `content` varchar(1000) NOT NULL DEFAULT '',
  `status` varchar(20) NOT NULL DEFAULT 'approved',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_shop_status` (`shop_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 店铺口コミ';

INSERT INTO `la_cbk_shop_review`
(`shop_id`, `member_name`, `rating`, `content`, `status`, `create_time`, `update_time`)
SELECT 12, '佐藤 美奈', 5.0, '店内の雰囲気が落ち着いていて、スタッフの方も丁寧でした。また利用したいと思います。', 'approved', UNIX_TIMESTAMP('2026-08-18 20:10:00'), UNIX_TIMESTAMP('2026-08-18 20:10:00')
WHERE NOT EXISTS (
  SELECT 1 FROM `la_cbk_shop_review` WHERE `shop_id` = 12 AND `member_name` = '佐藤 美奈'
);

INSERT INTO `la_cbk_shop_review`
(`shop_id`, `member_name`, `rating`, `content`, `status`, `create_time`, `update_time`)
SELECT 12, '田中 翔太', 4.8, '駅から近く、料金の説明も分かりやすかったです。安心して楽しい時間を過ごせました。', 'approved', UNIX_TIMESTAMP('2026-08-12 21:30:00'), UNIX_TIMESTAMP('2026-08-12 21:30:00')
WHERE NOT EXISTS (
  SELECT 1 FROM `la_cbk_shop_review` WHERE `shop_id` = 12 AND `member_name` = '田中 翔太'
);
