SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_member_delete_record` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `member_id` int unsigned NOT NULL DEFAULT 0 COMMENT '会员ID',
  `member_no` varchar(40) NOT NULL DEFAULT '' COMMENT '会员编号',
  `nickname` varchar(80) NOT NULL DEFAULT '' COMMENT '昵称',
  `mobile` varchar(40) NOT NULL DEFAULT '' COMMENT '手机号',
  `reason` varchar(500) NOT NULL DEFAULT '' COMMENT '删除原因',
  `status` varchar(40) NOT NULL DEFAULT 'requested' COMMENT '处理状态',
  `requested_time` int unsigned NOT NULL DEFAULT 0 COMMENT '申请时间',
  `processed_time` int unsigned NOT NULL DEFAULT 0 COMMENT '处理时间',
  `operator` varchar(80) NOT NULL DEFAULT '' COMMENT '处理人',
  `remark` varchar(500) NOT NULL DEFAULT '' COMMENT '备注',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `update_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_member_id` (`member_id`),
  KEY `idx_member_no` (`member_no`),
  KEY `idx_status` (`status`),
  KEY `idx_requested_time` (`requested_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 会员账号删除记录';
