SET NAMES utf8mb4;

UPDATE `la_config`
SET `value` = 'Caba Night総合管理画面',
    `update_time` = UNIX_TIMESTAMP()
WHERE `type` = 'website'
  AND `name` IN ('name', 'shop_name', 'pc_title');

INSERT INTO `la_config` (`type`, `name`, `value`, `create_time`, `update_time`)
SELECT 'website', 'name', 'Caba Night総合管理画面', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
WHERE NOT EXISTS (
    SELECT 1 FROM `la_config` WHERE `type` = 'website' AND `name` = 'name'
);

INSERT INTO `la_config` (`type`, `name`, `value`, `create_time`, `update_time`)
SELECT 'website', 'shop_name', 'Caba Night総合管理画面', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
WHERE NOT EXISTS (
    SELECT 1 FROM `la_config` WHERE `type` = 'website' AND `name` = 'shop_name'
);

INSERT INTO `la_config` (`type`, `name`, `value`, `create_time`, `update_time`)
SELECT 'website', 'pc_title', 'Caba Night総合管理画面', UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
WHERE NOT EXISTS (
    SELECT 1 FROM `la_config` WHERE `type` = 'website' AND `name` = 'pc_title'
);
