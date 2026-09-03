SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'C', 'プッシュ通知', 'el-icon-Bell', 874,
       'cabakura.pushNotification/lists', 'push-notification', 'cabakura/push-notification/index/index', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
    SELECT 1 FROM `la_system_menu`
    WHERE `pid` = 0 AND `paths` = 'push-notification'
);
