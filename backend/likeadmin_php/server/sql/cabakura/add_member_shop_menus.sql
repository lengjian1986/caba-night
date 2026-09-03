-- CABAKURA 补充菜单：会员列表、店铺列表、店铺创建动作。

SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

SET @cabakura = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'cabakura' ORDER BY `id` DESC LIMIT 1);
SET @shop = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'shop' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @cabakura, 'M', '会员管理', 'el-icon-User', 95, '', 'member', '', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'member'
);

SET @member = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'member' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @member, 'C', '会员列表', '', 100, 'cabakura.member/lists', 'lists', 'cabakura/member/lists/index', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @member AND `paths` = 'lists'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop, 'C', '店铺列表', '', 110, 'cabakura.shop/lists', 'lists', 'cabakura/shop/lists/index', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'lists'
);

SET @shop_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop_lists, 'A', '保存草稿', '', 100, 'cabakura.shop/saveDraft', '', '', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop_lists AND `perms` = 'cabakura.shop/saveDraft'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @shop_lists, 'A', '提交审核', '', 90, 'cabakura.shop/submitReview', '', '', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @shop_lists AND `perms` = 'cabakura.shop/submitReview'
);
