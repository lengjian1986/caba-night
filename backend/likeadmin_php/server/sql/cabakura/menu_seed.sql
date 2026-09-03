-- CABAKURA 手写业务后台菜单
-- 本文件只创建菜单和权限点，不创建业务表。
-- 执行前请确认当前库表前缀为 la_。

SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
VALUES
(0, 'M', 'CABAKURA', 'el-icon-Menu', 950, '', 'cabakura', '', '', '', 0, 1, 0, @now, @now);
SET @cabakura = LAST_INSERT_ID();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
VALUES
(@cabakura, 'C', '工作台', 'el-icon-Monitor', 100, 'cabakura.dashboard/summary', 'dashboard', 'cabakura/dashboard/index', '', '', 0, 1, 0, @now, @now),
(@cabakura, 'M', '店铺管理', 'el-icon-Shop', 90, '', 'shop', '', '', '', 0, 1, 0, @now, @now),
(@cabakura, 'M', 'Cast管理', 'local-icon-user_guanli', 85, '', 'cast', '', '', '', 0, 1, 0, @now, @now),
(@cabakura, 'M', '预约订单', 'el-icon-Tickets', 80, '', 'order', '', '', '', 0, 1, 0, @now, @now),
(@cabakura, 'C', '暗卷回答设定', 'local-icon-shezhi', 75, 'cabakura.answer_setting/fields', 'answer-setting', 'cabakura/answer-setting/index/index', '', '', 0, 1, 0, @now, @now),
(@cabakura, 'M', '客服中心', 'el-icon-Service', 70, '', 'support', '', '', '', 0, 1, 0, @now, @now);

SET @shop = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'shop' ORDER BY `id` DESC LIMIT 1);
SET @cast = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'cast' ORDER BY `id` DESC LIMIT 1);
SET @order = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'order' ORDER BY `id` DESC LIMIT 1);
SET @support = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'support' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
VALUES
(@shop, 'C', '店铺审核', '', 100, 'cabakura.shop/lists', 'review', 'cabakura/shop/review/index', '', '', 0, 1, 0, @now, @now),
(@cast, 'C', 'Cast列表', 'local-icon-user_guanli', 100, 'cabakura.cast/lists', 'lists', 'cabakura/cast/lists/index', '', '', 0, 1, 0, @now, @now),
(@order, 'C', '订单列表', '', 100, 'cabakura.order/lists', 'lists', 'cabakura/order/lists/index', '', '', 0, 1, 0, @now, @now),
(@support, 'C', '客服工单', '', 100, 'cabakura.support/tickets', 'ticket', 'cabakura/support/ticket/index', '', '', 0, 1, 0, @now, @now);

SET @shop_review = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'review' ORDER BY `id` DESC LIMIT 1);
SET @cast_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cast AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);
SET @order_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @order AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);
SET @answer_setting = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'answer-setting' ORDER BY `id` DESC LIMIT 1);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
VALUES
(@shop_review, 'A', '查看详情', '', 100, 'cabakura.shop/detail', '', '', '', '', 0, 1, 0, @now, @now),
(@shop_review, 'A', '审核通过', '', 90, 'cabakura.shop/approve', '', '', '', '', 0, 1, 0, @now, @now),
(@shop_review, 'A', '审核驳回', '', 80, 'cabakura.shop/reject', '', '', '', '', 0, 1, 0, @now, @now),
(@cast_lists, 'A', '保存Cast', '', 100, 'cabakura.cast/saveProfile', '', '', '', '', 0, 1, 0, @now, @now),
(@answer_setting, 'A', '保存选项', '', 100, 'cabakura.answer_setting/saveOption', '', '', '', '', 0, 1, 0, @now, @now),
(@answer_setting, 'A', '删除选项', '', 90, 'cabakura.answer_setting/deleteOption', '', '', '', '', 0, 1, 0, @now, @now),
(@order_lists, 'A', '确认预约', '', 100, 'cabakura.order/confirm', '', '', '', '', 0, 1, 0, @now, @now),
(@order_lists, 'A', '拒绝预约', '', 90, 'cabakura.order/reject', '', '', '', '', 0, 1, 0, @now, @now);
