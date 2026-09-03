SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();
SET @member = (
  SELECT `id` FROM `la_system_menu`
  WHERE `pid` = 0 AND `paths` = 'member'
  ORDER BY `id` DESC LIMIT 1
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @member, 'C', 'アカウント消去一覧', 'local-icon-shanchu', 95, 'cabakura.member/deleteRecords', 'delete-record', 'cabakura/member/delete-record/index', '', '', 0, 1, 0, @now, @now
WHERE @member IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM `la_system_menu`
  WHERE `pid` = @member AND `paths` = 'delete-record' AND `component` = 'cabakura/member/delete-record/index'
);

UPDATE `la_system_menu`
SET `name` = 'アカウント消去一覧',
    `icon` = 'local-icon-shanchu',
    `sort` = 95,
    `perms` = 'cabakura.member/deleteRecords',
    `component` = 'cabakura/member/delete-record/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `pid` = @member AND `paths` = 'delete-record';
