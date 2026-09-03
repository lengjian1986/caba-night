-- CABAKURA 暗卷回答设定：Cast 下拉选项字段。

SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();

SET @old_smoking = (SELECT `id` FROM `la_dict_type` WHERE `type` = 'cbk_cast_smoking_status' ORDER BY `id` DESC LIMIT 1);
SET @old_drinking = (SELECT `id` FROM `la_dict_type` WHERE `type` = 'cbk_cast_drinking_status' ORDER BY `id` DESC LIMIT 1);

DELETE FROM `la_dict_data`
WHERE `type_value` IN ('cbk_cast_smoking_status', 'cbk_cast_drinking_status')
   OR `type_id` IN (COALESCE(@old_smoking, 0), COALESCE(@old_drinking, 0));

DELETE FROM `la_dict_type`
WHERE `type` IN ('cbk_cast_smoking_status', 'cbk_cast_drinking_status');

INSERT INTO `la_dict_type`
(`name`, `type`, `status`, `remark`, `create_time`, `update_time`)
SELECT '喜欢类型', 'cbk_cast_preferred_male_type', 1, 'Cast喜欢类型下拉选项', @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_dict_type` WHERE `type` = 'cbk_cast_preferred_male_type'
);

INSERT INTO `la_dict_type`
(`name`, `type`, `status`, `remark`, `create_time`, `update_time`)
SELECT '抽烟喝酒', 'cbk_cast_smoking_drinking', 1, 'Cast抽烟喝酒合并下拉选项', @now, @now
WHERE NOT EXISTS (
  SELECT 1 FROM `la_dict_type` WHERE `type` = 'cbk_cast_smoking_drinking'
);

UPDATE `la_dict_type`
SET `name` = '喜欢类型', `status` = 1, `remark` = 'Cast喜欢类型下拉选项', `update_time` = @now
WHERE `type` = 'cbk_cast_preferred_male_type';

UPDATE `la_dict_type`
SET `name` = '抽烟喝酒', `status` = 1, `remark` = 'Cast抽烟喝酒合并下拉选项', `update_time` = @now
WHERE `type` = 'cbk_cast_smoking_drinking';
