SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

UPDATE `la_system_menu`
SET `pid` = 0,
    `name` = 'プッシュ通知',
    `icon` = 'el-icon-Bell',
    `perms` = 'cabakura.pushNotification/lists',
    `component` = 'cabakura/push-notification/index/index',
    `sort` = 874,
    `update_time` = @now
WHERE `paths` = 'push-notification'
  AND `component` = 'message/notice/index';
