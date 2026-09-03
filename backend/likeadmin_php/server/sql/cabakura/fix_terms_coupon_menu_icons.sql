SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

UPDATE `la_system_menu`
SET `icon` = 'el-icon-Document', `update_time` = @now
WHERE `paths` = 'terms' AND `component` = 'cabakura/terms/index/index';

UPDATE `la_system_menu`
SET `icon` = 'el-icon-Tickets', `update_time` = @now
WHERE `paths` = 'coupon' AND `component` = '';
