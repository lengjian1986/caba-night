SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_cast_schedule` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` int unsigned NOT NULL DEFAULT 0 COMMENT '店铺ID',
  `cast_id` int unsigned NOT NULL DEFAULT 0 COMMENT 'Cast ID',
  `work_date` date NOT NULL COMMENT '出勤日期',
  `start_time` varchar(20) NOT NULL DEFAULT '' COMMENT '开始时间',
  `end_time` varchar(20) NOT NULL DEFAULT '' COMMENT '结束时间',
  `attendance_status` varchar(40) NOT NULL DEFAULT 'scheduled' COMMENT '出勤状态',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_shop_date` (`shop_id`,`work_date`),
  KEY `idx_cast_date` (`cast_id`,`work_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA Cast出勤日历';
