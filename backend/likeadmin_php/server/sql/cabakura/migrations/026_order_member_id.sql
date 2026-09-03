SET @has_user_id := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'la_cbk_order'
    AND COLUMN_NAME = 'user_id'
);
SET @add_user_id_sql := IF(
  @has_user_id = 0,
  'ALTER TABLE `la_cbk_order` ADD COLUMN `user_id` int unsigned NOT NULL DEFAULT 0 COMMENT ''会员用户ID'' AFTER `id`, ADD KEY `idx_user_id` (`user_id`)',
  'SELECT 1'
);
PREPARE add_user_id_statement FROM @add_user_id_sql;
EXECUTE add_user_id_statement;
DEALLOCATE PREPARE add_user_id_statement;
