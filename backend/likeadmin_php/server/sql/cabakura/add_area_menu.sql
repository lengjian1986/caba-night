SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'C', 'エリア管理', 'local-icon-dingwei', 872, 'cabakura.area/lists', 'area', 'cabakura/area/index/index', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'area' AND `component` = 'cabakura/area/index/index'
);

SET @area = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = 0 AND `paths` = 'area' AND `component` = 'cabakura/area/index/index'
  ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET `name` = 'エリア管理',
    `icon` = 'local-icon-dingwei',
    `sort` = 872,
    `perms` = 'cabakura.area/lists',
    `component` = 'cabakura/area/index/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `id` = @area;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @area, 'A', '保存', '', 100, 'cabakura.area/save', 'save', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @area AND `perms` = 'cabakura.area/save'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @area, 'A', '表示切替', '', 90, 'cabakura.area/switchShow', 'switch-show', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @area AND `perms` = 'cabakura.area/switchShow'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @area, 'A', 'おすすめ切替', '', 80, 'cabakura.area/switchRecommended', 'switch-recommended', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @area AND `perms` = 'cabakura.area/switchRecommended'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @area, 'A', '削除', '', 70, 'cabakura.area/delete', 'delete', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @area AND `perms` = 'cabakura.area/delete'
);
