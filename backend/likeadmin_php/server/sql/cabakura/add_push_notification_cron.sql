SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();
INSERT INTO `la_dev_crontab`
(`name`,`type`,`system`,`remark`,`command`,`params`,`status`,`expression`,`last_time`,`time`,`max_time`,`create_time`,`update_time`)
SELECT 'プッシュ通知配信', 1, 1, '定時プッシュ通知を毎分配信', 'cabakura_push_notifications', '', 1, '* * * * *', 0, '0', '0', @now, @now
WHERE NOT EXISTS (SELECT 1 FROM `la_dev_crontab` WHERE `command` = 'cabakura_push_notifications' AND `delete_time` IS NULL);
