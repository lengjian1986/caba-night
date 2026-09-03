SET NAMES utf8mb4;

ALTER TABLE `la_cbk_member`
  ADD COLUMN `avatar` varchar(500) NOT NULL DEFAULT '' COMMENT '头像' AFTER `user_id`;
