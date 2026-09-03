-- 调整为 CABAKURA 项目后台菜单结构。
-- LikeAdmin 作为底座，不保留单独的 CABAKURA 一级入口。

SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

SET @cabakura = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'cabakura' ORDER BY `id` DESC LIMIT 1);
SET @dashboard = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'dashboard' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'dashboard' AND `component` = 'cabakura/dashboard/index' ORDER BY `id` DESC LIMIT 1)
);
SET @member = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'member' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'member' ORDER BY `id` DESC LIMIT 1)
);
SET @shop = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'shop' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'shop' ORDER BY `id` DESC LIMIT 1)
);
SET @cast = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'cast' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'cast' AND `component` = '' ORDER BY `id` DESC LIMIT 1)
);
SET @order = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'order' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'order' ORDER BY `id` DESC LIMIT 1)
);
SET @answer_setting = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'answer-setting' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'answer-setting' ORDER BY `id` DESC LIMIT 1)
);
SET @support = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'support' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'support' ORDER BY `id` DESC LIMIT 1)
);
SET @audit = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'audit' ORDER BY `id` DESC LIMIT 1);

-- 隐藏 LikeAdmin 默认业务/演示菜单。保留权限管理、系统设置。
UPDATE `la_system_menu`
SET `is_show` = 0, `is_disable` = 1, `update_time` = @now
WHERE `id` IN (
  5,   -- LikeAdmin 默认工作台
  117, -- 用户管理
  158, -- 应用管理
  166, -- 财务管理
  96,  -- 装修管理
  82,  -- 渠道设置
  25,  -- 组织管理
  148  -- 模板示例
);

-- 隐藏开发工具，避免出现 LikeAdmin 代码生成器。
UPDATE `la_system_menu`
SET `is_show` = 0, `is_disable` = 1, `update_time` = @now
WHERE `id` = 23 OR `paths` = 'dev_tools';

-- 将项目业务菜单提升为顶级菜单。
UPDATE `la_system_menu`
SET `pid` = 0, `name` = '工作台', `sort` = 1000, `paths` = 'dashboard', `component` = 'cabakura/dashboard/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @dashboard;

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '会员管理', `sort` = 900, `paths` = 'member', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @member;

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '店铺管理', `sort` = 890, `paths` = 'shop', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @shop;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'M', 'Cast管理', 'local-icon-user_guanli', 887, '', 'cast', '', '', '', 0, 1, 0, @now, @now
WHERE @cast IS NULL;

SET @cast = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'cast' AND `component` = '' ORDER BY `id` DESC LIMIT 1);

UPDATE `la_system_menu`
SET `pid` = 0, `name` = 'Cast管理', `icon` = 'local-icon-user_guanli', `sort` = 887, `paths` = 'cast', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @cast;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'M', '审核专栏', 'local-icon-yingyezizhi', 885, '', 'audit', '', '', '', 0, 1, 0, @now, @now
WHERE @audit IS NULL;

SET @audit = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'audit' ORDER BY `id` DESC LIMIT 1);

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '审核专栏', `icon` = 'local-icon-yingyezizhi', `sort` = 885, `paths` = 'audit', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @audit;

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '预约订单', `sort` = 880, `paths` = 'order', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @order;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'C', '暗卷回答设定', 'local-icon-shezhi', 875, 'cabakura.answer_setting/fields', 'answer-setting', 'cabakura/answer-setting/index/index', '', '', 0, 1, 0, @now, @now
WHERE @answer_setting IS NULL;

SET @answer_setting = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'answer-setting' ORDER BY `id` DESC LIMIT 1);

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '暗卷回答设定', `icon` = 'local-icon-shezhi', `sort` = 875, `perms` = 'cabakura.answer_setting/fields', `paths` = 'answer-setting', `component` = 'cabakura/answer-setting/index/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @answer_setting;

UPDATE `la_system_menu`
SET `pid` = 0, `name` = '客服中心', `sort` = 870, `paths` = 'support', `component` = '', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @support;

-- 补齐业务子菜单图标，使用 LikeAdmin 自带本地图标。
UPDATE `la_system_menu`
SET `icon` = 'local-icon-user_guanli', `update_time` = @now
WHERE `pid` = @member AND `paths` = 'lists';

UPDATE `la_system_menu`
SET `icon` = 'local-icon-dianpu_fengge', `update_time` = @now
WHERE `pid` = @shop AND `paths` = 'lists';

UPDATE `la_system_menu`
SET `icon` = 'local-icon-user_guanli', `update_time` = @now
WHERE `pid` = @cast AND `paths` = 'lists';

UPDATE `la_system_menu`
SET `icon` = 'local-icon-yingyezizhi', `update_time` = @now
WHERE `pid` = @shop AND `paths` = 'review';

SET @shop_review = COALESCE(
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @audit AND `paths` = 'shop' AND `component` = 'cabakura/shop/review/index' ORDER BY `id` DESC LIMIT 1),
  (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'review' AND `component` = 'cabakura/shop/review/index' ORDER BY `id` DESC LIMIT 1)
);

UPDATE `la_system_menu`
SET `pid` = @audit, `name` = '店铺审核', `icon` = 'local-icon-dianpu_fengge', `sort` = 90, `paths` = 'shop', `component` = 'cabakura/shop/review/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `id` = @shop_review;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @audit, 'C', '本人认证审核', 'local-icon-user_guanli', 100, 'cabakura.member/lists', 'member', 'cabakura/audit/member/index', '', '', 0, 1, 0, @now, @now
WHERE @audit IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @audit AND `paths` = 'member'
);

UPDATE `la_system_menu`
SET `name` = '本人认证审核', `icon` = 'local-icon-user_guanli', `sort` = 100, `perms` = 'cabakura.member/lists', `component` = 'cabakura/audit/member/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `pid` = @audit AND `paths` = 'member';

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @audit, 'C', 'Cast审核', 'local-icon-user_guanli', 80, '', 'cast', 'cabakura/audit/cast/index', '', '', 0, 1, 0, @now, @now
WHERE @audit IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @audit AND `paths` = 'cast'
);

UPDATE `la_system_menu`
SET `name` = 'Cast审核', `icon` = 'local-icon-user_guanli', `sort` = 80, `component` = 'cabakura/audit/cast/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `pid` = @audit AND `paths` = 'cast';

SET @audit_member = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @audit AND `paths` = 'member' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @audit_member, 'A', '通过本人认证', '', 100, 'cabakura.member/approveIdentity', '', '', '', '', 0, 1, 0, @now, @now
WHERE @audit_member IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @audit_member AND `perms` = 'cabakura.member/approveIdentity'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @audit_member, 'A', '驳回本人认证', '', 90, 'cabakura.member/rejectIdentity', '', '', '', '', 0, 1, 0, @now, @now
WHERE @audit_member IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @audit_member AND `perms` = 'cabakura.member/rejectIdentity'
);

UPDATE `la_system_menu`
SET `icon` = 'local-icon-dingdan', `update_time` = @now
WHERE `pid` = @order AND `paths` = 'lists';

UPDATE `la_system_menu`
SET `icon` = 'local-icon-kefu', `update_time` = @now
WHERE `pid` = @support AND `paths` = 'ticket';

SET @member_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @member AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);
SET @shop_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);
SET @shop_manager = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'manager' ORDER BY `id` DESC LIMIT 1);
SET @cast_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cast AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);
SET @shop_edit = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'edit' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @member, 'C', '会员详情', '', 90, 'cabakura.member/detail', 'detail', 'cabakura/member/detail/index', '/member/lists', '', 0, 0, 0, @now, @now
WHERE @member IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @member AND `paths` = 'detail'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @member_lists, 'A', '修改资料', '', 100, 'cabakura.member/updateProfile', '', '', '', '', 0, 1, 0, @now, @now
WHERE @member_lists IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @member_lists AND `perms` = 'cabakura.member/updateProfile'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop, 'C', '店铺编辑', '', 90, 'cabakura.shop/detail', 'edit', 'cabakura/shop/edit/index', '/shop/lists', '', 0, 0, 0, @now, @now
WHERE @shop IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'edit'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop_lists, 'A', '编辑店铺', '', 80, 'cabakura.shop/updateInfo', '', '', '', '', 0, 1, 0, @now, @now
WHERE @shop_lists IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop_lists AND `perms` = 'cabakura.shop/updateInfo'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop, 'C', '商铺管理者', 'local-icon-user_guanli', 95, 'cabakura.shop_manager/lists', 'manager', 'cabakura/shop/manager/index', '', '', 0, 1, 0, @now, @now
WHERE @shop IS NOT NULL AND @shop_manager IS NULL;

UPDATE `la_system_menu`
SET `name` = '商铺管理者', `icon` = 'local-icon-user_guanli', `sort` = 95, `perms` = 'cabakura.shop_manager/lists', `paths` = 'manager', `component` = 'cabakura/shop/manager/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `pid` = @shop AND `paths` = 'manager';

SET @shop_manager = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'manager' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop_manager, 'A', '保存商铺管理者', '', 100, 'cabakura.shop_manager/save', '', '', '', '', 0, 1, 0, @now, @now
WHERE @shop_manager IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop_manager AND `perms` = 'cabakura.shop_manager/save'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop_manager, 'A', '删除商铺管理者', '', 90, 'cabakura.shop_manager/delete', '', '', '', '', 0, 1, 0, @now, @now
WHERE @shop_manager IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop_manager AND `perms` = 'cabakura.shop_manager/delete'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @cast, 'C', 'Cast列表', 'local-icon-user_guanli', 100, 'cabakura.cast/lists', 'lists', 'cabakura/cast/lists/index', '', '', 0, 1, 0, @now, @now
WHERE @cast IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @cast AND `paths` = 'lists'
);

UPDATE `la_system_menu`
SET `name` = 'Cast列表', `icon` = 'local-icon-user_guanli', `sort` = 100, `perms` = 'cabakura.cast/lists', `paths` = 'lists', `component` = 'cabakura/cast/lists/index', `is_show` = 1, `is_disable` = 0, `update_time` = @now
WHERE `pid` = @cast AND `paths` = 'lists';

SET @cast_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cast AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @cast_lists, 'A', '保存Cast', '', 100, 'cabakura.cast/saveProfile', '', '', '', '', 0, 1, 0, @now, @now
WHERE @cast_lists IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @cast_lists AND `perms` = 'cabakura.cast/saveProfile'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @answer_setting, 'A', '保存选项', '', 100, 'cabakura.answer_setting/saveOption', '', '', '', '', 0, 1, 0, @now, @now
WHERE @answer_setting IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @answer_setting AND `perms` = 'cabakura.answer_setting/saveOption'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @answer_setting, 'A', '删除选项', '', 90, 'cabakura.answer_setting/deleteOption', '', '', '', '', 0, 1, 0, @now, @now
WHERE @answer_setting IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @answer_setting AND `perms` = 'cabakura.answer_setting/deleteOption'
);

UPDATE `la_system_menu`
SET `is_show` = 0, `is_disable` = 1, `update_time` = @now
WHERE `pid` = @shop_edit AND `perms` IN ('cabakura.cast/lists', 'cabakura.cast/saveProfile');

-- 隐藏原 CABAKURA 容器菜单，避免被当作子项目入口。
UPDATE `la_system_menu`
SET `is_show` = 0, `is_disable` = 1, `update_time` = @now
WHERE `id` = @cabakura;
