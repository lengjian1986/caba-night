SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT 0, 'C', 'ニュース管理', 'local-icon-tongzhi_mian', 873, 'cabakura.news/lists', 'news', 'cabakura/news/index/index', '', '', 0, 1, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = 0 AND `paths` = 'news' AND `component` = 'cabakura/news/index/index'
);

SET @news = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = 0 AND `paths` = 'news' AND `component` = 'cabakura/news/index/index'
  ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET `name` = 'ニュース管理',
    `icon` = 'local-icon-tongzhi_mian',
    `sort` = 873,
    `perms` = 'cabakura.news/lists',
    `component` = 'cabakura/news/index/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `id` = @news;

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @news, 'A', '保存', '', 100, 'cabakura.news/save', 'save', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @news AND `perms` = 'cabakura.news/save'
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @news, 'A', '表示切替', '', 90, 'cabakura.news/switchShow', 'switch-show', '', '', '', 0, 0, 0, @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_system_menu` WHERE `pid` = @news AND `perms` = 'cabakura.news/switchShow'
);
