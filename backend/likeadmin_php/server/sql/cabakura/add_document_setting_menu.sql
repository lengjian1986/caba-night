SET NAMES utf8mb4;

SET @now = UNIX_TIMESTAMP();

SET @setting_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = 0 AND `paths` = 'setting'
    ORDER BY `id` DESC LIMIT 1
);

INSERT INTO `la_system_menu`
    (`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT
    @setting_id, 'C', 'ドキュメント設定', 'el-icon-Document', 55, 'setting.document/getConfig', 'document', 'setting/document/index', '', '', 0, 1, 0, @now, @now
WHERE @setting_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM `la_system_menu`
      WHERE `pid` = @setting_id AND `paths` = 'document' AND `component` = 'setting/document/index'
  );

SET @document_id = (
    SELECT `id` FROM `la_system_menu`
    WHERE `pid` = @setting_id AND `paths` = 'document' AND `component` = 'setting/document/index'
    ORDER BY `id` DESC LIMIT 1
);

UPDATE `la_system_menu`
SET
    `name` = 'ドキュメント設定',
    `icon` = 'el-icon-Document',
    `sort` = 55,
    `perms` = 'setting.document/getConfig',
    `component` = 'setting/document/index',
    `is_show` = 1,
    `is_disable` = 0,
    `update_time` = @now
WHERE `id` = @document_id;

INSERT INTO `la_system_menu`
    (`pid`, `type`, `name`, `icon`, `sort`, `perms`, `paths`, `component`, `selected`, `params`, `is_cache`, `is_show`, `is_disable`, `create_time`, `update_time`)
SELECT
    @document_id, 'A', '保存', '', 100, 'setting.document/setConfig', '', '', '', '', 0, 1, 0, @now, @now
WHERE @document_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM `la_system_menu`
      WHERE `pid` = @document_id AND `perms` = 'setting.document/setConfig'
  );
