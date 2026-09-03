SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `la_cbk_support_message` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ticket_id` int unsigned NOT NULL DEFAULT 0 COMMENT '客服工单ID',
  `sender_type` varchar(40) NOT NULL DEFAULT 'member' COMMENT '发送者类型 member/admin/shop',
  `sender_name` varchar(120) NOT NULL DEFAULT '' COMMENT '发送者名称',
  `content` text COMMENT '消息内容',
  `create_time` int unsigned NOT NULL DEFAULT 0,
  `delete_time` int unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ticket_id` (`ticket_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='CABAKURA 客服对话消息';

INSERT INTO `la_cbk_support_message`
(`ticket_id`, `sender_type`, `sender_name`, `content`, `create_time`)
SELECT
  `id`,
  'member',
  `member_name`,
  `last_message`,
  `update_time`
FROM `la_cbk_support_ticket`
WHERE `last_message` <> ''
  AND NOT EXISTS (
    SELECT 1
    FROM `la_cbk_support_message`
    WHERE `la_cbk_support_message`.`ticket_id` = `la_cbk_support_ticket`.`id`
  );
