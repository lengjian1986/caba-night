SET NAMES utf8mb4;

UPDATE `la_cbk_shop`
SET `description` = '大阪市エリアで気軽にご利用いただける店舗です。落ち着いた接客と明朗な料金案内で、初めてのお客様にも安心してお過ごしいただけます。'
WHERE `name` = 'CabaGO test' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '新宿エリアで上質な時間をお楽しみいただける店舗です。華やかで落ち着いた店内にて、丁寧な接客でお客様をお迎えいたします。'
WHERE `name` = 'クラブ 桜' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '歌舞伎町の中心に位置する、洗練された雰囲気の店舗です。会話を大切にした丁寧なサービスで、特別な夜をお過ごしいただけます。'
WHERE `name` = 'Club Orion Tokyo' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '銀座らしい上品で落ち着いた空間をご用意しています。きめ細やかな接客とゆったりとした時間をお楽しみいただける店舗です。'
WHERE `name` = 'Ginza Lumiere' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '六本木エリアで特別なひとときを提供する店舗です。落ち着いた接客と充実した空間で、ゆっくりとお寛ぎいただけます。'
WHERE `name` = 'Roppongi Velvet' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '渋谷駅からアクセスしやすく、明るく親しみやすい雰囲気の店舗です。初めてのお客様にも分かりやすいご案内を心がけています。'
WHERE `name` = 'Shibuya Noel' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '梅田エリアでゆったりとした時間をお楽しみいただける店舗です。明朗な料金案内と丁寧なサービスで、幅広いお客様をお迎えいたします。'
WHERE `name` = 'Umeda Ciel' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = 'なんば駅から近く、気軽にお立ち寄りいただける店舗です。親しみやすい雰囲気と丁寧な接客で、心地よい時間をご提供いたします。'
WHERE `name` = 'Namba Stella' AND (`description` IS NULL OR `description` = '');

UPDATE `la_cbk_shop`
SET `description` = '心斎橋エリアで落ち着いた大人の時間を楽しめる店舗です。上質な空間ときめ細やかな接客で、お客様をお迎えいたします。'
WHERE `name` = 'Shinsaibashi Ray' AND (`description` IS NULL OR `description` = '');
