SET NAMES utf8mb4;

ALTER TABLE `la_cbk_shop`
  ADD COLUMN `description` text COMMENT '店铺说明' AFTER `price_range`;
