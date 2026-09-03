-- Development seed data for home/admin preview.
-- Idempotent by shop name and cast name within shop.

SET NAMES utf8mb4;
SET @now := UNIX_TIMESTAMP();

CREATE TEMPORARY TABLE tmp_cbk_seed_shops (
  name varchar(120) NOT NULL,
  kana varchar(120) NOT NULL,
  area varchar(120) NOT NULL,
  phone varchar(40) NOT NULL,
  email varchar(120) NOT NULL,
  address varchar(255) NOT NULL,
  station varchar(120) NOT NULL,
  business_hours varchar(80) NOT NULL,
  price_range varchar(120) NOT NULL,
  tags varchar(500) NOT NULL,
  package_sets text,
  logo_image varchar(500) NOT NULL,
  shop_images text,
  license_no varchar(120) NOT NULL,
  license_holder_name varchar(120) NOT NULL,
  business_status varchar(40) NOT NULL,
  booking_enabled tinyint unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO tmp_cbk_seed_shops VALUES
('Club Orion Tokyo', 'クラブ オリオン トウキョウ', '東京都 新宿区', '03-6380-1101', 'orion.tokyo@example.dev', '東京都新宿区歌舞伎町1-8-1', '新宿駅 徒歩5分', '20:00-LAST', '¥8,000~¥16,000 / 60分', '["高級感","明朗会計","当日予約OK"]', '[{"name":"Orion First Set","description":"初回来店向けの60分セット。指名なしでも利用しやすいプランです。","image":"/uploads/images/20260814/2026081410324481ffa6560.png","cast_names":["一条 玲奈","桐谷 美咲"],"price":12000,"discount_type":"percent","discount_value":20,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time"]}]', '/uploads/images/20260814/2026081410324481ffa6560.png', '["/uploads/images/20260814/2026081410324481ffa6560.png","/uploads/images/20260814/202608141033280ffb40423.jpg"]', 'TOKYO-DEV-0001', '株式会社 Orion Tokyo', '営業中', 1),
('Ginza Lumiere', 'ギンザ ルミエール', '東京都 中央区', '03-6264-2202', 'lumiere.ginza@example.dev', '東京都中央区銀座6-4-12', '銀座駅 徒歩3分', '19:30-LAST', '¥10,000~¥20,000 / 60分', '["落ち着いた上質空間","初回歓迎"]', '[{"name":"Lumiere Elegant Set","description":"銀座エリア向けの上質な初回セット。","image":"/uploads/images/20260814/20260814103223c48cf2234.png","cast_names":["白石 エマ","花咲 りり"],"price":15000,"discount_type":"amount","discount_value":3000,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time","time free"]}]', '/uploads/images/20260814/20260814103223c48cf2234.png', '["/uploads/images/20260814/20260814103223c48cf2234.png","/uploads/images/20260814/202608141103223f7b54480.png"]', 'TOKYO-DEV-0002', '株式会社 Lumiere', '営業中', 1),
('Roppongi Velvet', 'ロッポンギ ベルベット', '東京都 港区', '03-6434-3303', 'velvet.roppongi@example.dev', '東京都港区六本木3-10-8', '六本木駅 徒歩4分', '20:00-LAST', '¥9,000~¥18,000 / 60分', '["英語対応","VIP個室","深夜営業"]', '[{"name":"Velvet VIP Set","description":"VIPルーム利用を想定したおすすめセット。","image":"/uploads/images/20260814/202608141038395c3b01624.jpeg","cast_names":["神崎 ゆあ","橘 せな"],"price":18000,"discount_type":"percent","discount_value":15,"limit_type":"usage_count","valid_range":[],"usage_limit":30,"max_people":3,"status":"public","tags":["time free"]}]', '/uploads/images/20260814/202608141038395c3b01624.jpeg', '["/uploads/images/20260814/202608141038395c3b01624.jpeg","/uploads/images/20260814/202608141102556eea87394.png"]', 'TOKYO-DEV-0003', '株式会社 Velvet', '営業中', 1),
('Shibuya Noel', 'シブヤ ノエル', '東京都 渋谷区', '03-6455-4404', 'noel.shibuya@example.dev', '東京都渋谷区道玄坂2-12-5', '渋谷駅 徒歩6分', '20:00-1:00', '¥7,000~¥14,000 / 60分', '["カジュアル","駅近","当日予約OK"]', '[{"name":"Noel Casual Set","description":"渋谷で気軽に使える60分セット。","image":"/uploads/images/20260814/202608141103223f7b54480.png","cast_names":["早乙女 まい","月城 かれん"],"price":9000,"discount_type":"amount","discount_value":1000,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time"]}]', '/uploads/images/20260814/202608141103223f7b54480.png', '["/uploads/images/20260814/202608141103223f7b54480.png","/uploads/images/20260814/2026081410324481ffa6560.png"]', 'TOKYO-DEV-0004', '株式会社 Noel', '営業中', 1),
('Umeda Ciel', 'ウメダ シエル', '大阪府 大阪市 北区', '06-6312-5101', 'ciel.umeda@example.dev', '大阪府大阪市北区堂山町7-18', '梅田駅 徒歩5分', '20:00-LAST', '¥7,000~¥15,000 / 60分', '["梅田","明朗会計","団体OK"]', '[{"name":"Ciel Welcome Set","description":"梅田エリアの初回歓迎セット。","image":"/uploads/images/20260814/2026081410324481ffa6560.png","cast_names":["藤原 あや","南 ことね"],"price":11000,"discount_type":"percent","discount_value":20,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time","time free"]}]', '/uploads/images/20260814/2026081410324481ffa6560.png', '["/uploads/images/20260814/2026081410324481ffa6560.png","/uploads/images/20260814/202608141033280ffb40423.jpg"]', 'OSAKA-DEV-0001', '株式会社 Ciel', '営業中', 1),
('Namba Stella', 'ナンバ ステラ', '大阪府 大阪市 中央区', '06-6211-5202', 'stella.namba@example.dev', '大阪府大阪市中央区難波1-6-9', 'なんば駅 徒歩3分', '19:30-LAST', '¥6,000~¥13,000 / 60分', '["なんば","初回歓迎","駅近"]', '[{"name":"Stella Trial Set","description":"なんば駅近で使いやすい初回セット。","image":"/uploads/images/20260814/20260814103223c48cf2234.png","cast_names":["星野 りこ","相沢 なな"],"price":8500,"discount_type":"amount","discount_value":1500,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time"]}]', '/uploads/images/20260814/20260814103223c48cf2234.png', '["/uploads/images/20260814/20260814103223c48cf2234.png","/uploads/images/20260814/202608141103223f7b54480.png"]', 'OSAKA-DEV-0002', '株式会社 Stella', '営業中', 1),
('Shinsaibashi Ray', 'シンサイバシ レイ', '大阪府 大阪市 中央区', '06-6245-5303', 'ray.shinsaibashi@example.dev', '大阪府大阪市中央区東心斎橋1-15-11', '心斎橋駅 徒歩4分', '20:00-LAST', '¥8,000~¥16,000 / 60分', '["心斎橋","VIP個室","深夜営業"]', '[{"name":"Ray Premium Set","description":"心斎橋でゆったり楽しめるプレミアムセット。","image":"/uploads/images/20260814/202608141038395c3b01624.jpeg","cast_names":["七瀬 ゆい","朝比奈 りん"],"price":14000,"discount_type":"percent","discount_value":10,"limit_type":"usage_count","valid_range":[],"usage_limit":20,"max_people":3,"status":"public","tags":["time free"]}]', '/uploads/images/20260814/202608141038395c3b01624.jpeg', '["/uploads/images/20260814/202608141038395c3b01624.jpeg","/uploads/images/20260814/202608141102556eea87394.png"]', 'OSAKA-DEV-0003', '株式会社 Ray', '営業中', 1),
('Tennoji Bloom', 'テンノウジ ブルーム', '大阪府 大阪市 天王寺区', '06-6773-5404', 'bloom.tennoji@example.dev', '大阪府大阪市天王寺区悲田院町8-22', '天王寺駅 徒歩5分', '20:00-1:00', '¥6,000~¥12,000 / 60分', '["天王寺","カジュアル","当日予約OK"]', '[{"name":"Bloom Standard Set","description":"天王寺で使いやすい標準セット。","image":"/uploads/images/20260814/202608141103223f7b54480.png","cast_names":["三浦 さき","小川 まり"],"price":7800,"discount_type":"amount","discount_value":800,"limit_type":"date_range","valid_range":["2026-08-01","2026-12-31"],"usage_limit":0,"max_people":2,"status":"public","tags":["first time"]}]', '/uploads/images/20260814/202608141103223f7b54480.png', '["/uploads/images/20260814/202608141103223f7b54480.png","/uploads/images/20260814/2026081410324481ffa6560.png"]', 'OSAKA-DEV-0004', '株式会社 Bloom', '営業中', 1);

UPDATE la_cbk_shop s
JOIN tmp_cbk_seed_shops seed ON seed.name = s.name
SET
  s.manager_id = IF(s.manager_id > 0, s.manager_id, 1),
  s.kana = seed.kana,
  s.area = seed.area,
  s.phone = seed.phone,
  s.email = seed.email,
  s.address = seed.address,
  s.station = seed.station,
  s.business_hours = seed.business_hours,
  s.price_range = seed.price_range,
  s.tags = seed.tags,
  s.package_sets = seed.package_sets,
  s.logo_image = seed.logo_image,
  s.shop_images = seed.shop_images,
  s.license_no = seed.license_no,
  s.license_holder_name = seed.license_holder_name,
  s.license_expires_at = '2027-12-31',
  s.license_file_name = '',
  s.license_files = '[]',
  s.review_status = 'approved',
  s.business_status = seed.business_status,
  s.booking_enabled = seed.booking_enabled,
  s.submitted_at = @now,
  s.update_time = @now,
  s.delete_time = NULL;

INSERT INTO la_cbk_shop
(manager_id, name, kana, area, phone, email, address, station, business_hours, price_range, tags, package_sets, logo_image, shop_images, license_no, license_holder_name, license_expires_at, license_file_name, license_files, review_status, business_status, booking_enabled, submitted_at, create_time, update_time, delete_time)
SELECT
  1, seed.name, seed.kana, seed.area, seed.phone, seed.email, seed.address, seed.station, seed.business_hours, seed.price_range, seed.tags, seed.package_sets, seed.logo_image, seed.shop_images, seed.license_no, seed.license_holder_name, '2027-12-31', '', '[]', 'approved', seed.business_status, seed.booking_enabled, @now, @now, @now, NULL
FROM tmp_cbk_seed_shops seed
WHERE NOT EXISTS (
  SELECT 1 FROM la_cbk_shop s WHERE s.name = seed.name
);

CREATE TEMPORARY TABLE tmp_cbk_seed_casts (
  shop_name varchar(120) NOT NULL,
  name varchar(120) NOT NULL,
  kana varchar(120) NOT NULL,
  age tinyint unsigned NOT NULL,
  height smallint unsigned NOT NULL,
  measurements varchar(80) NOT NULL,
  preferred_male_type varchar(255) NOT NULL,
  smoking_drinking varchar(80) NOT NULL,
  profile text,
  main_image varchar(500) NOT NULL,
  gallery_images text,
  tags varchar(500) NOT NULL,
  attendance_status varchar(40) NOT NULL,
  is_new tinyint unsigned NOT NULL,
  is_recommended tinyint unsigned NOT NULL,
  sort int unsigned NOT NULL,
  rating decimal(3,2) NOT NULL,
  favorite_count int unsigned NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO tmp_cbk_seed_casts VALUES
('Club Orion Tokyo','一条 玲奈','イチジョウ レナ',24,162,'B86/W57/H85','清潔感がある方','吸わない・少し飲む','落ち着いた接客が得意な東京エリアのCASTです。','/uploads/images/20260814/202608141038395c3b01624.jpeg','["/uploads/images/20260814/202608141038395c3b01624.jpeg"]','["上品","聞き上手"]','working',1,1,980,4.82,128),
('Club Orion Tokyo','桐谷 美咲','キリタニ ミサキ',23,160,'B84/W56/H84','優しい方','吸わない・飲む','明るく自然な会話が得意です。','/uploads/images/20260814/202608141102556eea87394.png','["/uploads/images/20260814/202608141102556eea87394.png"]','["明るい","新人"]','scheduled',1,1,970,4.76,96),
('Ginza Lumiere','白石 エマ','シライシ エマ',25,164,'B88/W58/H86','紳士的な方','吸わない・少し飲む','銀座らしい落ち着いた雰囲気のCASTです。','/uploads/images/20260814/20260814103223c48cf2234.png','["/uploads/images/20260814/20260814103223c48cf2234.png"]','["癒し系","上品"]','working',0,1,960,4.88,156),
('Ginza Lumiere','花咲 りり','ハナサキ リリ',22,158,'B83/W55/H83','会話を楽しめる方','吸わない・飲む','初回のお客様にも話しやすい接客です。','/uploads/images/20260814/202608141103223f7b54480.png','["/uploads/images/20260814/202608141103223f7b54480.png"]','["可愛い","初々しい"]','scheduled',1,0,950,4.63,74),
('Roppongi Velvet','神崎 ゆあ','カンザキ ユア',26,166,'B90/W59/H88','余裕のある方','吸わない・飲む','六本木エリアのVIP対応が得意です。','/uploads/images/20260814/202608141033280ffb40423.jpg','["/uploads/images/20260814/202608141033280ffb40423.jpg"]','["VIP対応","大人"]','working',0,1,940,4.91,184),
('Roppongi Velvet','橘 せな','タチバナ セナ',24,163,'B85/W57/H85','楽しく飲める方','少し吸う・飲む','テンポの良い会話が得意です。','/uploads/images/20260814/202608141038395c3b01624.jpeg','["/uploads/images/20260814/202608141038395c3b01624.jpeg"]','["クール","会話上手"]','off',0,0,930,4.58,68),
('Shibuya Noel','早乙女 まい','サオトメ マイ',21,157,'B82/W55/H82','優しい方','吸わない・少し飲む','渋谷らしい明るい雰囲気です。','/uploads/images/20260814/202608141102556eea87394.png','["/uploads/images/20260814/202608141102556eea87394.png"]','["元気","新人"]','scheduled',1,1,920,4.69,89),
('Shibuya Noel','月城 かれん','ツキシロ カレン',25,165,'B87/W58/H87','落ち着いた方','吸わない・飲む','ゆっくり話したい方におすすめです。','/uploads/images/20260814/2026081410324481ffa6560.png','["/uploads/images/20260814/2026081410324481ffa6560.png"]','["癒し系","聞き上手"]','working',0,1,910,4.80,112),
('Umeda Ciel','藤原 あや','フジワラ アヤ',24,161,'B86/W57/H85','清潔感がある方','吸わない・少し飲む','梅田エリアで人気のCASTです。','/uploads/images/20260814/202608141038395c3b01624.jpeg','["/uploads/images/20260814/202608141038395c3b01624.jpeg"]','["大阪","親しみやすい"]','working',0,1,900,4.84,132),
('Umeda Ciel','南 ことね','ミナミ コトネ',22,159,'B83/W56/H83','話しやすい方','吸わない・飲む','初回でも自然に楽しめる接客です。','/uploads/images/20260814/202608141102556eea87394.png','["/uploads/images/20260814/202608141102556eea87394.png"]','["明るい","新人"]','scheduled',1,0,890,4.61,70),
('Namba Stella','星野 りこ','ホシノ リコ',23,160,'B84/W56/H84','楽しい方','吸わない・少し飲む','なんばでカジュアルに楽しめます。','/uploads/images/20260814/20260814103223c48cf2234.png','["/uploads/images/20260814/20260814103223c48cf2234.png"]','["可愛い","駅近"]','working',1,1,880,4.77,104),
('Namba Stella','相沢 なな','アイザワ ナナ',25,164,'B88/W58/H86','落ち着いた方','吸わない・飲む','落ち着いた会話と丁寧な接客です。','/uploads/images/20260814/202608141103223f7b54480.png','["/uploads/images/20260814/202608141103223f7b54480.png"]','["上品","癒し系"]','off',0,0,870,4.55,62),
('Shinsaibashi Ray','七瀬 ゆい','ナナセ ユイ',24,162,'B86/W57/H86','紳士的な方','吸わない・飲む','心斎橋エリアのおすすめCASTです。','/uploads/images/20260814/202608141033280ffb40423.jpg','["/uploads/images/20260814/202608141033280ffb40423.jpg"]','["人気","会話上手"]','working',0,1,860,4.86,144),
('Shinsaibashi Ray','朝比奈 りん','アサヒナ リン',22,158,'B82/W55/H82','優しい方','吸わない・少し飲む','笑顔の接客が得意です。','/uploads/images/20260814/202608141038395c3b01624.jpeg','["/uploads/images/20260814/202608141038395c3b01624.jpeg"]','["新人","可愛い"]','scheduled',1,0,850,4.66,82),
('Tennoji Bloom','三浦 さき','ミウラ サキ',26,165,'B89/W59/H87','余裕のある方','少し吸う・飲む','天王寺エリアで落ち着いて楽しめます。','/uploads/images/20260814/202608141102556eea87394.png','["/uploads/images/20260814/202608141102556eea87394.png"]','["大人","落ち着き"]','working',0,1,840,4.79,118),
('Tennoji Bloom','小川 まり','オガワ マリ',23,160,'B84/W56/H84','会話を楽しめる方','吸わない・少し飲む','柔らかい雰囲気のCASTです。','/uploads/images/20260814/2026081410324481ffa6560.png','["/uploads/images/20260814/2026081410324481ffa6560.png"]','["癒し系","親しみやすい"]','scheduled',1,0,830,4.60,73);

UPDATE la_cbk_cast c
JOIN la_cbk_shop s ON s.id = c.shop_id
JOIN tmp_cbk_seed_casts seed ON seed.shop_name = s.name AND seed.name = c.name
SET
  c.kana = seed.kana,
  c.age = seed.age,
  c.height = seed.height,
  c.measurements = seed.measurements,
  c.preferred_male_type = seed.preferred_male_type,
  c.smoking_drinking = seed.smoking_drinking,
  c.profile = seed.profile,
  c.main_image = seed.main_image,
  c.gallery_images = seed.gallery_images,
  c.tags = seed.tags,
  c.attendance_status = seed.attendance_status,
  c.review_status = 'approved',
  c.is_new = seed.is_new,
  c.is_recommended = seed.is_recommended,
  c.sort = seed.sort,
  c.rating = seed.rating,
  c.favorite_count = seed.favorite_count,
  c.update_time = @now,
  c.delete_time = NULL;

INSERT INTO la_cbk_cast
(shop_id, name, kana, age, height, measurements, preferred_male_type, smoking_drinking, smoking_status, drinking_status, profile, main_image, gallery_images, tags, attendance_status, review_status, is_new, is_recommended, sort, rating, favorite_count, create_time, update_time, delete_time)
SELECT
  s.id, seed.name, seed.kana, seed.age, seed.height, seed.measurements, seed.preferred_male_type, seed.smoking_drinking, 'unknown', 'unknown', seed.profile, seed.main_image, seed.gallery_images, seed.tags, seed.attendance_status, 'approved', seed.is_new, seed.is_recommended, seed.sort, seed.rating, seed.favorite_count, @now, @now, NULL
FROM tmp_cbk_seed_casts seed
JOIN la_cbk_shop s ON s.name = seed.shop_name
WHERE NOT EXISTS (
  SELECT 1
  FROM la_cbk_cast c
  WHERE c.shop_id = s.id AND c.name = seed.name
);

DROP TEMPORARY TABLE IF EXISTS tmp_cbk_seed_casts;
DROP TEMPORARY TABLE IF EXISTS tmp_cbk_seed_shops;
