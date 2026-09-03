SET NAMES utf8mb4;

ALTER TABLE `la_cbk_news`
  ADD COLUMN `title` varchar(255) NOT NULL DEFAULT '' COMMENT 'タイトル' AFTER `logo_image`,
  ADD COLUMN `link` varchar(500) NOT NULL DEFAULT '' COMMENT 'リンク先' AFTER `title`;
