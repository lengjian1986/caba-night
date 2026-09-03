SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

SET @permission_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = 0 AND `paths` = 'permission'
    ORDER BY `id` DESC LIMIT 1
);

SET @setting_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = 0 AND `paths` = 'setting'
    ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET `name` = '権限管理', `update_time` = @now
WHERE `id` = @permission_id;

UPDATE `la_system_menu`
SET `name` = 'メニュー', `update_time` = @now
WHERE `pid` = @permission_id AND `paths` = 'menu';

UPDATE `la_system_menu`
SET `name` = 'ロール', `update_time` = @now
WHERE `pid` = @permission_id AND `paths` = 'role';

UPDATE `la_system_menu`
SET `name` = '管理者', `update_time` = @now
WHERE `pid` = @permission_id AND `paths` = 'admin';

UPDATE `la_system_menu`
SET `name` = 'システム設定', `update_time` = @now
WHERE `id` = @setting_id;

UPDATE `la_system_menu`
SET `name` = 'サイト設定', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'website';

UPDATE `la_system_menu`
SET `name` = 'ユーザー設定', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'user';

UPDATE `la_system_menu`
SET `name` = '決済設定', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'pay';

UPDATE `la_system_menu`
SET `name` = 'ストレージ設定', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'storage';

UPDATE `la_system_menu`
SET `name` = '人気検索', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'search';

UPDATE `la_system_menu`
SET `name` = 'システム保守', `update_time` = @now
WHERE `pid` = @setting_id AND `paths` = 'system';

SET @website_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = @setting_id AND `paths` = 'website'
    ORDER BY `id` DESC LIMIT 1
);

SET @user_setting_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = @setting_id AND `paths` = 'user'
    ORDER BY `id` DESC LIMIT 1
);

SET @pay_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = @setting_id AND `paths` = 'pay'
    ORDER BY `id` DESC LIMIT 1
);

SET @system_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = @setting_id AND `paths` = 'system'
    ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET `name` = 'サイト情報', `update_time` = @now
WHERE `pid` = @website_id AND `paths` = 'information';

UPDATE `la_system_menu`
SET `name` = 'サイト届出', `update_time` = @now
WHERE `pid` = @website_id AND `paths` = 'filing';

UPDATE `la_system_menu`
SET `name` = 'ポリシー規約', `update_time` = @now
WHERE `pid` = @website_id AND `paths` = 'protocol';

UPDATE `la_system_menu`
SET `name` = 'アクセス解析', `update_time` = @now
WHERE `pid` = @website_id AND `paths` = 'statistics';

UPDATE `la_system_menu`
SET `name` = 'ユーザー設定', `update_time` = @now
WHERE `pid` = @user_setting_id AND `paths` = 'setup';

UPDATE `la_system_menu`
SET `name` = 'ログイン・登録', `update_time` = @now
WHERE `pid` = @user_setting_id AND `paths` = 'login_register';

UPDATE `la_system_menu`
SET `name` = '決済方法', `update_time` = @now
WHERE `pid` = @pay_id AND `paths` = 'method';

UPDATE `la_system_menu`
SET `name` = '決済設定', `update_time` = @now
WHERE `pid` = @pay_id AND `paths` = 'config';

UPDATE `la_system_menu`
SET `name` = '定期タスク', `update_time` = @now
WHERE `pid` = @system_id AND `paths` = 'scheduled_task';

UPDATE `la_system_menu`
SET `name` = 'システムログ', `update_time` = @now
WHERE `pid` = @system_id AND `paths` = 'journal';

UPDATE `la_system_menu`
SET `name` = 'システムキャッシュ', `update_time` = @now
WHERE `pid` = @system_id AND `paths` = 'cache';

UPDATE `la_system_menu`
SET `name` = 'システム環境', `update_time` = @now
WHERE `pid` = @system_id AND `paths` = 'environment';
