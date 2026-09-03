SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

UPDATE `la_system_menu` SET `icon` = 'local-icon-user_guanli', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `component` IN ('cabakura/cast/lists/index', 'cabakura/audit/cast/index') AND (`icon` IS NULL OR `icon` = '' OR `icon` = 'local-icon-user');

UPDATE `la_system_menu` SET `icon` = 'local-icon-shezhi_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'information' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-yingyezizhi', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'filing' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-anquan', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'protocol' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-shuju', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'statistics' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-shijian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'scheduled_task' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-rizhi', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'journal' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-qingchu', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'cache' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-set_weihu', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'environment' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-weixin_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'config' AND `component` = 'channel/wx_oa/config' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-guanli', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'menu' AND `component` = 'channel/wx_oa/menu' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-kuaijiehuifu', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'follow' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-sousuo', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'keyword' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-tongzhi', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'default' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-shouye_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'mobile' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-shuju_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'pc' AND `pid` <> 175 AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-tongzhi_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'notice' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-xiaoxi', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'short_letter' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-set_user', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'setup' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-anquan_mian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'login_register' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-tupian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'icon' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-bianji', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'rich_text' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-shangchuan', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'upload' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-jianpan', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'popover_input' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-sucai', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'file' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-youjian', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'link' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-gengduo', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'overflow' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-fukuan', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'method' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-set_pay', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'config' AND `component` = 'setting/pay/config/index' AND (`icon` IS NULL OR `icon` = '');

UPDATE `la_system_menu` SET `icon` = 'local-icon-user_guanli', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'users' AND `component` = 'cabakura/subscription/users/index' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-heshoujilu', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'records' AND `component` = 'cabakura/subscription/records/index' AND (`icon` IS NULL OR `icon` = '');
UPDATE `la_system_menu` SET `icon` = 'local-icon-set_pay', `update_time` = @now WHERE `is_show` = 1 AND `type` IN ('M', 'C') AND `paths` = 'plans' AND `component` = 'cabakura/subscription/plans/index' AND (`icon` IS NULL OR `icon` = '');
