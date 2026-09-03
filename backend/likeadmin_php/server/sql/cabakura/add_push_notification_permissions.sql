SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();
SET @push = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = 0 AND `paths` = 'push-notification'
  ORDER BY `id` DESC LIMIT 1
);

INSERT INTO `la_system_menu`
(`pid`,`type`,`name`,`icon`,`sort`,`perms`,`paths`,`component`,`selected`,`params`,`is_cache`,`is_show`,`is_disable`,`create_time`,`update_time`)
SELECT @push,'A','保存','',100,'cabakura.pushNotification/save','save','','','',0,0,0,@now,@now
WHERE @push IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM `la_system_menu`
    WHERE `pid` = @push AND `perms` = 'cabakura.pushNotification/save'
  );
