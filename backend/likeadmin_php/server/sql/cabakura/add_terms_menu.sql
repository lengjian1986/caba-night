SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();
INSERT INTO `la_system_menu` (`pid`,`type`,`name`,`icon`,`sort`,`perms`,`paths`,`component`,`selected`,`params`,`is_cache`,`is_show`,`is_disable`,`create_time`,`update_time`)
SELECT 0,'C','利用規約','local-icon-wenben',872,'cabakura.terms/lists','terms','cabakura/terms/index/index','','',0,1,0,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM `la_system_menu` WHERE `pid`=0 AND `paths`='terms');
SET @terms=(SELECT `id` FROM `la_system_menu` WHERE `pid`=0 AND `paths`='terms' ORDER BY id DESC LIMIT 1);
UPDATE `la_system_menu` SET `name`='利用規約',`component`='cabakura/terms/index/index',`perms`='cabakura.terms/lists',`is_show`=1,`is_disable`=0,`update_time`=@now WHERE `id`=@terms;
INSERT INTO `la_system_menu` (`pid`,`type`,`name`,`icon`,`sort`,`perms`,`paths`,`component`,`selected`,`params`,`is_cache`,`is_show`,`is_disable`,`create_time`,`update_time`)
SELECT @terms,'A','保存','',100,'cabakura.terms/save','save','','','',0,0,0,@now,@now WHERE NOT EXISTS (SELECT 1 FROM `la_system_menu` WHERE `pid`=@terms AND `perms`='cabakura.terms/save');
INSERT INTO `la_system_menu` (`pid`,`type`,`name`,`icon`,`sort`,`perms`,`paths`,`component`,`selected`,`params`,`is_cache`,`is_show`,`is_disable`,`create_time`,`update_time`)
SELECT @terms,'A','表示切替','',90,'cabakura.terms/switchShow','switch-show','','','',0,0,0,@now,@now WHERE NOT EXISTS (SELECT 1 FROM `la_system_menu` WHERE `pid`=@terms AND `perms`='cabakura.terms/switchShow');
