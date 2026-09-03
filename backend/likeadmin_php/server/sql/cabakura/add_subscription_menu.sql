SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'M', 'サブスク管理', 'local-icon-huiyuanyingxiao', 872, '', 'subscription', '', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'subscription'
);

SET @subscription = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = 0 AND `paths` = 'subscription'
  ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET `name` = 'サブスク管理',
    `icon` = 'local-icon-huiyuanyingxiao',
    `sort` = 872,
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `id` = @subscription;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @subscription, 'C', '契約中ユーザー一覧', 'local-icon-user_guanli', 100, 'cabakura.subscription/users', 'users', 'cabakura/subscription/users/index', '', '', 0, 1, 0, @now, @now
WHERE @subscription IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @subscription AND `paths` = 'users'
);

UPDATE `la_system_menu`
SET `name` = '契約中ユーザー一覧',
    `icon` = 'local-icon-user_guanli',
    `sort` = 100,
    `perms` = 'cabakura.subscription/users',
    `component` = 'cabakura/subscription/users/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `pid` = @subscription AND `paths` = 'users';

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @subscription, 'C', 'サブスク記録', 'local-icon-heshoujilu', 90, 'cabakura.subscription/records', 'records', 'cabakura/subscription/records/index', '', '', 0, 1, 0, @now, @now
WHERE @subscription IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @subscription AND `paths` = 'records'
);

UPDATE `la_system_menu`
SET `name` = 'サブスク記録',
    `icon` = 'local-icon-heshoujilu',
    `sort` = 90,
    `perms` = 'cabakura.subscription/records',
    `component` = 'cabakura/subscription/records/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `pid` = @subscription AND `paths` = 'records';

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @subscription, 'C', 'サブスクPlan設定', 'local-icon-set_pay', 80, 'cabakura.subscription/plans', 'plans', 'cabakura/subscription/plans/index', '', '', 0, 1, 0, @now, @now
WHERE @subscription IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @subscription AND `paths` = 'plans'
);

UPDATE `la_system_menu`
SET `name` = 'サブスクPlan設定',
    `icon` = 'local-icon-set_pay',
    `sort` = 80,
    `perms` = 'cabakura.subscription/plans',
    `component` = 'cabakura/subscription/plans/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `pid` = @subscription AND `paths` = 'plans';

SET @plans = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = @subscription AND `paths` = 'plans'
  ORDER BY `id` DESC LIMIT 1
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @plans, 'A', '保存Plan', '', 100, 'cabakura.subscription/savePlan', 'save-plan', '', '', '', 0, 0, 0, @now, @now
WHERE @plans IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @plans AND `perms` = 'cabakura.subscription/savePlan'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @plans, 'A', '有効切替', '', 90, 'cabakura.subscription/switchPlan', 'switch-plan', '', '', '', 0, 0, 0, @now, @now
WHERE @plans IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @plans AND `perms` = 'cabakura.subscription/switchPlan'
);
