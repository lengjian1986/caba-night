SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

UPDATE `la_system_menu`
SET `icon` = CASE
    WHEN `type` = 'M' THEN 'el-icon-Menu'
    ELSE 'el-icon-Document'
END,
`update_time` = @now
WHERE `is_show` = 1
  AND `type` IN ('M', 'C')
  AND (`icon` IS NULL OR `icon` = '');
