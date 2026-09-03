SET NAMES utf8mb4;

UPDATE `la_cbk_cast`
SET
  `style` = ELT(MOD(`id` - 1, 6) + 1,
    '細身', 'スレンダー', '普通体型', 'グラマー', '小柄', 'モデル体型'),
  `blood_type` = ELT(MOD(`id` - 1, 4) + 1,
    'A型', 'B型', 'O型', 'AB型'),
  `birthplace` = ELT(MOD(`id` - 1, 8) + 1,
    '東京都', '神奈川県', '埼玉県', '千葉県', '大阪府', '京都府', '愛知県', '福岡県'),
  `hobby` = ELT(MOD(`id` - 1, 8) + 1,
    '美容・カフェ巡り', '映画鑑賞', '旅行', '料理', '音楽鑑賞', 'ショッピング', '読書', 'カメラ'),
  `attendance_frequency` = ELT(MOD(`id` - 1, 6) + 1,
    '週2〜3日', '週3〜4日', '週4〜5日', '週5日', '平日中心', '週末中心'),
  `update_time` = UNIX_TIMESTAMP()
WHERE `delete_time` IS NULL;
