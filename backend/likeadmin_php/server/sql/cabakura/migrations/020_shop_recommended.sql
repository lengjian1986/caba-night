SET NAMES utf8mb4;

ALTER TABLE `la_cbk_shop`
  ADD COLUMN `is_recommended` tinyint unsigned NOT NULL DEFAULT 0 COMMENT '人気店舗表示' AFTER `business_status`;

ALTER TABLE `la_cbk_shop`
  ADD KEY `idx_is_recommended` (`is_recommended`);
