SET NAMES utf8mb4;

SET @cast_lists = (
  SELECT `id` FROM `la_system_menu`
  WHERE `perms` = 'cabakura.cast/lists'
  ORDER BY `id` DESC LIMIT 1
);

INSERT INTO `la_system_menu`
(`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT @cast_lists, 'A', '人気キャスト表示切替', '', 70, 'cabakura.cast/switchRecommended', '', '', '', '', 0, 1, 0, UNIX_TIMESTAMP(), UNIX_TIMESTAMP()
WHERE @cast_lists IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM `la_system_menu` WHERE `pid` = @cast_lists AND `perms` = 'cabakura.cast/switchRecommended'
  );
