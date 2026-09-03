SET @has_remark := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_order'
    AND COLUMN_NAME = 'remark'
);
SET @add_remark_sql := IF(
  @has_remark = 0,
  'ALTER TABLE `la_cbk_order` ADD COLUMN `remark` varchar(500) NOT NULL DEFAULT '''' COMMENT ''预约备注'' AFTER `pay_status_text`',
  'SELECT 1'
);
PREPARE add_remark_statement FROM @add_remark_sql;
EXECUTE add_remark_statement;
DEALLOCATE PREPARE add_remark_statement;
