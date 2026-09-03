SET NAMES utf8mb4;

ALTER TABLE `la_cbk_member`
  ADD COLUMN `user_id` int unsigned NOT NULL DEFAULT 0 COMMENT '关联 la_user.id' AFTER `id`,
  ADD COLUMN `email` varchar(120) NOT NULL DEFAULT '' COMMENT '邮箱' AFTER `mobile`,
  ADD COLUMN `nationality` varchar(80) NOT NULL DEFAULT '' COMMENT '国籍' AFTER `email`,
  ADD COLUMN `postal_code` varchar(20) NOT NULL DEFAULT '' COMMENT '邮编' AFTER `nationality`,
  ADD COLUMN `address` varchar(255) NOT NULL DEFAULT '' COMMENT '居住地' AFTER `postal_code`,
  ADD COLUMN `building_name` varchar(255) NOT NULL DEFAULT '' COMMENT '建筑名与房间号' AFTER `address`,
  ADD KEY `idx_user_id` (`user_id`);
