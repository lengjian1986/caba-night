SET NAMES utf8mb4;

SET @columns_to_add := 'ALTER TABLE `la_cbk_cast`
  ADD COLUMN `style` varchar(255) NOT NULL DEFAULT '''' COMMENT ''スタイル'' AFTER `measurements`,
  ADD COLUMN `blood_type` varchar(40) NOT NULL DEFAULT '''' COMMENT ''血液型'' AFTER `style`,
  ADD COLUMN `birthplace` varchar(255) NOT NULL DEFAULT '''' COMMENT ''出身地'' AFTER `blood_type`,
  ADD COLUMN `hobby` varchar(255) NOT NULL DEFAULT '''' COMMENT ''趣味'' AFTER `birthplace`,
  ADD COLUMN `attendance_frequency` varchar(120) NOT NULL DEFAULT '''' COMMENT ''出勤頻度'' AFTER `hobby`';

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'la_cbk_cast'
     AND COLUMN_NAME = 'style') = 0,
  @columns_to_add,
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
