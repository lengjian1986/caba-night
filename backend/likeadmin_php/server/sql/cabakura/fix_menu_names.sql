-- 修复 CABAKURA 菜单名称字符集乱码。

SET NAMES utf8mb4;

SET @cabakura = (SELECT `id` FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'cabakura' ORDER BY `id` DESC LIMIT 1);
SET @shop = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'shop' ORDER BY `id` DESC LIMIT 1);
SET @order = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'order' ORDER BY `id` DESC LIMIT 1);
SET @support = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @cabakura AND `paths` = 'support' ORDER BY `id` DESC LIMIT 1);
SET @shop_review = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @shop AND `paths` = 'review' ORDER BY `id` DESC LIMIT 1);
SET @order_lists = (SELECT `id` FROM `la_system_menu` WHERE `pid` = @order AND `paths` = 'lists' ORDER BY `id` DESC LIMIT 1);

UPDATE `la_system_menu` SET `name` = 'CABAKURA' WHERE `id` = @cabakura;
UPDATE `la_system_menu` SET `name` = '工作台' WHERE `pid` = @cabakura AND `paths` = 'dashboard';
UPDATE `la_system_menu` SET `name` = '店铺管理' WHERE `id` = @shop;
UPDATE `la_system_menu` SET `name` = '预约订单' WHERE `id` = @order;
UPDATE `la_system_menu` SET `name` = '客服中心' WHERE `id` = @support;
UPDATE `la_system_menu` SET `name` = '店铺审核' WHERE `id` = @shop_review;
UPDATE `la_system_menu` SET `name` = '订单列表' WHERE `id` = @order_lists;
UPDATE `la_system_menu` SET `name` = '客服工单' WHERE `pid` = @support AND `paths` = 'ticket';
UPDATE `la_system_menu` SET `name` = '查看详情' WHERE `pid` = @shop_review AND `perms` = 'cabakura.shop/detail';
UPDATE `la_system_menu` SET `name` = '审核通过' WHERE `pid` = @shop_review AND `perms` = 'cabakura.shop/approve';
UPDATE `la_system_menu` SET `name` = '审核驳回' WHERE `pid` = @shop_review AND `perms` = 'cabakura.shop/reject';
UPDATE `la_system_menu` SET `name` = '确认预约' WHERE `pid` = @order_lists AND `perms` = 'cabakura.order/confirm';
UPDATE `la_system_menu` SET `name` = '拒绝预约' WHERE `pid` = @order_lists AND `perms` = 'cabakura.order/reject';
