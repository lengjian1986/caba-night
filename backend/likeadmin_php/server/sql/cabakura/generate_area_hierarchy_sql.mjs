import { writeFileSync } from 'node:fs'

const prefUrl = 'https://raw.githubusercontent.com/OtterSou/japan-municipalities/main/1-pref.tsv'
const municipalityUrl = 'https://raw.githubusercontent.com/OtterSou/japan-municipalities/main/3-muni.tsv'
const wardUrl = 'https://raw.githubusercontent.com/OtterSou/japan-municipalities/main/4-ward.tsv'

const escapeSql = (value) => String(value ?? '').replaceAll('\\', '\\\\').replaceAll("'", "''")
const value = (value) => `'${escapeSql(value)}'`

const parseTsv = (text) => {
  const [headerLine, ...lines] = text.trim().split(/\r?\n/)
  const headers = headerLine.split('\t')
  return lines
    .filter(Boolean)
    .map((line) => {
      const values = line.split('\t')
      return Object.fromEntries(headers.map((header, index) => [header, values[index] ?? '']))
    })
}

const prefRows = await fetch(prefUrl).then((res) => res.text()).then(parseTsv)
const municipalityRows = await fetch(municipalityUrl).then((res) => res.text()).then(parseTsv)
const wardRows = await fetch(wardUrl).then((res) => res.text()).then(parseTsv)
const now = 'UNIX_TIMESTAMP()'

const prefecturePopulationOrder = [
  '13',
  '27',
  '14',
  '23',
  '11',
  '12',
  '28',
  '40',
  '01',
  '22',
  '08',
  '34',
  '26',
  '04',
  '15',
  '20',
  '21',
  '10',
  '09',
  '33',
  '07',
  '24',
  '43',
  '46',
  '47',
  '25',
  '35',
  '38',
  '42',
  '29',
  '02',
  '03',
  '44',
  '17',
  '06',
  '45',
  '16',
  '05',
  '37',
  '30',
  '19',
  '41',
  '18',
  '36',
  '39',
  '32',
  '31',
]
const prefectureSort = new Map(
  prefecturePopulationOrder.map((prefCode, index) => [prefCode, 10000 - index]),
)

const prefectureValues = prefRows
  .map((item) => {
    const sort = prefectureSort.get(item.pref) ?? 0
    return `(${value(item.code)}, '', ${value(item['full-ja'])}, ${value(item['full-ja-hira'])}, ${value(item['full-ja'])}, '', 0, 1, ${sort}, 1, 0, ${now}, ${now})`
  })
  .join(',\n')

const recommendedSort = new Map([
  ['13102', 10000],
  ['13103', 9900],
  ['13104', 9800],
  ['13113', 9700],
  ['27127', 9600],
  ['27100', 9500],
  ['23100', 9400],
  ['14100', 9300],
  ['40130', 9200],
  ['01100', 9100],
  ['26100', 9000]
])

const municipalityValues = municipalityRows
  .filter((item) => item.code && item.pref && item['full-ja'])
  .map((item) => {
    const sort = recommendedSort.get(item.code) ?? 0
    const recommended = recommendedSort.has(item.code) ? 1 : 0
    const pref = prefRows.find((prefecture) => prefecture.pref === item.pref)?.['full-ja'] ?? ''
    return `(${value(item.code)}, ${value(`${item.pref}000`)}, ${value(item['full-ja'])}, ${value(item['full-ja-hira'])}, ${value(pref)}, ${value(item['full-ja'])}, 0, 2, ${sort}, 1, ${recommended}, ${now}, ${now})`
  })
  .join(',\n')

const wardValues = wardRows
  .filter((item) => item.code && item.pref && item.muni && item['full-ja'])
  .map((item) => {
    const sort = recommendedSort.get(item.code) ?? 0
    const recommended = recommendedSort.has(item.code) ? 1 : 0
    const pref = prefRows.find((prefecture) => prefecture.pref === item.pref)?.['full-ja'] ?? ''
    return `(${value(item.code)}, ${value(item.muni)}, ${value(item['full-ja'])}, ${value(item['full-ja-hira'])}, ${value(pref)}, ${value(item['full-ja'])}, 0, 3, ${sort}, 1, ${recommended}, ${now}, ${now})`
  })
  .join(',\n')

const sql = `SET NAMES utf8mb4;

-- Data source:
--   Prefectures: ${prefUrl}
--   Municipalities: ${municipalityUrl}
--   Wards: ${wardUrl}
-- Source project: OtterSou/japan-municipalities

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD COLUMN \`parent_id\` int unsigned NOT NULL DEFAULT 0 COMMENT ''親エリアID'' AFTER \`id\`',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND column_name = 'parent_id'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD COLUMN \`level\` tinyint unsigned NOT NULL DEFAULT 2 COMMENT ''1:都道府県 2:市区町村 3:区'' AFTER \`parent_id\`',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND column_name = 'level'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD COLUMN \`code\` varchar(16) NOT NULL DEFAULT '''' COMMENT ''地方公共団体コード'' AFTER \`level\`',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND column_name = 'code'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD COLUMN \`parent_code\` varchar(16) NOT NULL DEFAULT '''' COMMENT ''親地方公共団体コード'' AFTER \`code\`',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND column_name = 'parent_code'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD COLUMN \`kana\` varchar(120) NOT NULL DEFAULT '''' COMMENT ''かな'' AFTER \`name\`',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND column_name = 'kana'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE \`la_cbk_area\`
SET \`code\` = CONCAT('legacy-', \`id\`), \`update_time\` = UNIX_TIMESTAMP()
WHERE \`code\` = '';

SET @ddl := (
  SELECT IF(
    COUNT(*) > 0,
    'ALTER TABLE \`la_cbk_area\` DROP INDEX \`uniq_name\`',
    'SELECT 1'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND index_name = 'uniq_name'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD UNIQUE KEY \`uniq_code\` (\`code\`)',
    'SELECT 1'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND index_name = 'uniq_code'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @ddl := (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE \`la_cbk_area\` ADD KEY \`idx_parent_level\` (\`parent_id\`, \`level\`)',
    'SELECT 1'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'la_cbk_area'
    AND index_name = 'idx_parent_level'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE \`la_cbk_area\`
SET \`delete_time\` = UNIX_TIMESTAMP(), \`update_time\` = UNIX_TIMESTAMP()
WHERE (\`code\` = '' OR \`code\` LIKE 'legacy-%')
  AND \`delete_time\` IS NULL
  AND \`name\` IN ('銀座', '六本木', '新宿・歌舞伎町', '恵比寿', '梅田', '北新地');

INSERT INTO \`la_cbk_area\`
(\`code\`, \`parent_code\`, \`name\`, \`kana\`, \`prefecture\`, \`city\`, \`parent_id\`, \`level\`, \`sort\`, \`is_show\`, \`is_recommended\`, \`create_time\`, \`update_time\`)
VALUES
${prefectureValues}
ON DUPLICATE KEY UPDATE
  \`parent_code\` = VALUES(\`parent_code\`),
  \`name\` = VALUES(\`name\`),
  \`kana\` = VALUES(\`kana\`),
  \`prefecture\` = VALUES(\`prefecture\`),
  \`city\` = VALUES(\`city\`),
  \`parent_id\` = VALUES(\`parent_id\`),
  \`level\` = VALUES(\`level\`),
  \`sort\` = VALUES(\`sort\`),
  \`is_show\` = VALUES(\`is_show\`),
  \`update_time\` = VALUES(\`update_time\`),
  \`delete_time\` = NULL;

INSERT INTO \`la_cbk_area\`
(\`code\`, \`parent_code\`, \`name\`, \`kana\`, \`prefecture\`, \`city\`, \`parent_id\`, \`level\`, \`sort\`, \`is_show\`, \`is_recommended\`, \`create_time\`, \`update_time\`)
VALUES
${municipalityValues}
ON DUPLICATE KEY UPDATE
  \`parent_code\` = VALUES(\`parent_code\`),
  \`name\` = VALUES(\`name\`),
  \`kana\` = VALUES(\`kana\`),
  \`prefecture\` = VALUES(\`prefecture\`),
  \`city\` = VALUES(\`city\`),
  \`level\` = VALUES(\`level\`),
  \`sort\` = GREATEST(\`sort\`, VALUES(\`sort\`)),
  \`is_show\` = VALUES(\`is_show\`),
  \`is_recommended\` = GREATEST(\`is_recommended\`, VALUES(\`is_recommended\`)),
  \`update_time\` = VALUES(\`update_time\`),
  \`delete_time\` = NULL;

UPDATE \`la_cbk_area\` city
INNER JOIN \`la_cbk_area\` pref
  ON pref.\`level\` = 1
  AND pref.\`code\` = city.\`parent_code\`
  AND pref.\`delete_time\` IS NULL
SET city.\`parent_id\` = pref.\`id\`
WHERE city.\`level\` = 2
  AND city.\`delete_time\` IS NULL;

INSERT INTO \`la_cbk_area\`
(\`code\`, \`parent_code\`, \`name\`, \`kana\`, \`prefecture\`, \`city\`, \`parent_id\`, \`level\`, \`sort\`, \`is_show\`, \`is_recommended\`, \`create_time\`, \`update_time\`)
VALUES
${wardValues}
ON DUPLICATE KEY UPDATE
  \`parent_code\` = VALUES(\`parent_code\`),
  \`name\` = VALUES(\`name\`),
  \`kana\` = VALUES(\`kana\`),
  \`prefecture\` = VALUES(\`prefecture\`),
  \`city\` = VALUES(\`city\`),
  \`level\` = VALUES(\`level\`),
  \`sort\` = GREATEST(\`sort\`, VALUES(\`sort\`)),
  \`is_show\` = VALUES(\`is_show\`),
  \`is_recommended\` = GREATEST(\`is_recommended\`, VALUES(\`is_recommended\`)),
  \`update_time\` = VALUES(\`update_time\`),
  \`delete_time\` = NULL;

UPDATE \`la_cbk_area\` ward
INNER JOIN \`la_cbk_area\` city
  ON city.\`level\` = 2
  AND city.\`code\` = ward.\`parent_code\`
  AND city.\`delete_time\` IS NULL
SET ward.\`parent_id\` = city.\`id\`
WHERE ward.\`level\` = 3
  AND ward.\`delete_time\` IS NULL;
`

writeFileSync(new URL('./schema/018_area_hierarchy.sql', import.meta.url), sql)
