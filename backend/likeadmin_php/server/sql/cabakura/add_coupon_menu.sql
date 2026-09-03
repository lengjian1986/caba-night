SET NAMES utf8mb4;
SET @now = UNIX_TIMESTAMP();
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT 0,'M','クーポン','local-icon-youhuiquan',871,'','coupon','','','',0,1,0,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=0 AND paths='coupon');
SET @coupon=(SELECT id FROM la_system_menu WHERE pid=0 AND paths='coupon' ORDER BY id DESC LIMIT 1);
UPDATE la_system_menu SET name='クーポン',icon='local-icon-youhuiquan',sort=871,is_show=1,is_disable=0,update_time=@now WHERE id=@coupon;
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @coupon,'C','クーポン設定','local-icon-shezhi',100,'cabakura.coupon/settings','settings','cabakura/coupon/settings/index','','',0,1,0,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@coupon AND paths='settings');
UPDATE la_system_menu SET name='クーポン設定',perms='cabakura.coupon/settings',component='cabakura/coupon/settings/index',is_show=1,is_disable=0,update_time=@now WHERE pid=@coupon AND paths='settings';
SET @settings=(SELECT id FROM la_system_menu WHERE pid=@coupon AND paths='settings' ORDER BY id DESC LIMIT 1);
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @settings,'A','クーポン保存','',100,'cabakura.coupon/save','save','','','',0,0,0,@now,@now WHERE @settings IS NOT NULL AND NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@settings AND perms='cabakura.coupon/save');
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @settings,'A','適用店舗取得','',90,'cabakura.coupon/shops','shops','','','',0,0,0,@now,@now WHERE @settings IS NOT NULL AND NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@settings AND perms='cabakura.coupon/shops');
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @settings,'A','会員一覧取得','',80,'cabakura.coupon/members','members','','','',0,0,0,@now,@now WHERE @settings IS NOT NULL AND NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@settings AND perms='cabakura.coupon/members');
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @settings,'A','クーポン配布','',70,'cabakura.coupon/distribute','distribute','','','',0,0,0,@now,@now WHERE @settings IS NOT NULL AND NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@settings AND perms='cabakura.coupon/distribute');
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @coupon,'C','クーポン利用履歴','local-icon-heshoujilu',90,'cabakura.coupon/usage','usage','cabakura/coupon/usage/index','','',0,1,0,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@coupon AND paths='usage');
UPDATE la_system_menu SET name='クーポン利用履歴',perms='cabakura.coupon/usage',component='cabakura/coupon/usage/index',is_show=1,is_disable=0,update_time=@now WHERE pid=@coupon AND paths='usage';
INSERT INTO la_system_menu (pid,type,name,icon,sort,perms,paths,component,selected,params,is_cache,is_show,is_disable,create_time,update_time)
SELECT @coupon,'C','クーポン配布履歴','local-icon-fenxiang',80,'cabakura.coupon/distribution','distribution','cabakura/coupon/distribution/index','','',0,1,0,@now,@now
WHERE NOT EXISTS (SELECT 1 FROM la_system_menu WHERE pid=@coupon AND paths='distribution');
UPDATE la_system_menu SET name='クーポン配布履歴',perms='cabakura.coupon/distribution',component='cabakura/coupon/distribution/index',is_show=1,is_disable=0,update_time=@now WHERE pid=@coupon AND paths='distribution';
