<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\CabakuraCast;
use app\common\model\dict\DictData;

class CastLogic
{
    private const DICT_PREFERRED_MALE_TYPE = 'cbk_cast_preferred_male_type';
    private const DICT_SMOKING_DRINKING = 'cbk_cast_smoking_drinking';

    public static function lists(array $params): array
    {
        $allowSearch = ['shop_id', 'keyword'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 20), 1);

        $query = CabakuraCast::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,shop_id,name,kana,age,height,measurements,style,blood_type,birthplace,hobby,attendance_frequency,preferred_male_type,smoking_drinking,smoking_status,drinking_status,profile,main_image,gallery_images,tags,attendance_status,review_status,is_new,is_popular,is_recommended,sort,rating,favorite_count,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('sort desc,id desc')
            ->select()
            ->toArray();

        $dictTextMap = self::dictTextMap([
            self::DICT_PREFERRED_MALE_TYPE,
            self::DICT_SMOKING_DRINKING,
        ]);
        foreach ($lists as &$item) {
            $item['attendance_status_text'] = self::attendanceStatusText((string)$item['attendance_status']);
            $item['review_status_text'] = self::reviewStatusText((string)$item['review_status']);
            $item['preferred_male_type_text'] = $dictTextMap[self::DICT_PREFERRED_MALE_TYPE][(string)$item['preferred_male_type']] ?? (string)$item['preferred_male_type'];
            $item['smoking_drinking_text'] = $dictTextMap[self::DICT_SMOKING_DRINKING][(string)$item['smoking_drinking']] ?? (string)$item['smoking_drinking'];
            $item['smoking_status_text'] = self::smokingStatusText((string)$item['smoking_status']);
            $item['drinking_status_text'] = self::drinkingStatusText((string)$item['drinking_status']);
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function saveProfile(array $params): int
    {
        $data = self::payload($params);
        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            CabakuraCast::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $cast = CabakuraCast::create($data);
        return (int)$cast->id;
    }

    public static function switchRecommended(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0 || CabakuraCast::findOrEmpty($id)->isEmpty()) {
            return false;
        }

        CabakuraCast::update([
            'id' => $id,
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'update_time' => time(),
        ]);
        return true;
    }

    public static function switchPopular(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0 || CabakuraCast::findOrEmpty($id)->isEmpty()) {
            return false;
        }

        CabakuraCast::update([
            'id' => $id,
            'is_popular' => empty($params['is_popular']) ? 0 : 1,
            'update_time' => time(),
        ]);
        return true;
    }

    private static function payload(array $params): array
    {
        return [
            'shop_id' => (int)($params['shop_id'] ?? 0),
            'name' => trim((string)($params['name'] ?? '')),
            'kana' => trim((string)($params['kana'] ?? '')),
            'age' => max((int)($params['age'] ?? 0), 0),
            'height' => max((int)($params['height'] ?? 0), 0),
            'measurements' => trim((string)($params['measurements'] ?? '')),
            'style' => trim((string)($params['style'] ?? '')),
            'blood_type' => trim((string)($params['blood_type'] ?? '')),
            'birthplace' => trim((string)($params['birthplace'] ?? '')),
            'hobby' => trim((string)($params['hobby'] ?? '')),
            'attendance_frequency' => trim((string)($params['attendance_frequency'] ?? '')),
            'preferred_male_type' => trim((string)($params['preferred_male_type'] ?? '')),
            'smoking_drinking' => trim((string)($params['smoking_drinking'] ?? '')),
            'smoking_status' => trim((string)($params['smoking_status'] ?? 'unknown')),
            'drinking_status' => trim((string)($params['drinking_status'] ?? 'unknown')),
            'profile' => trim((string)($params['profile'] ?? '')),
            'main_image' => trim((string)($params['main_image'] ?? '')),
            'gallery_images' => json_encode(self::normalizeStringList($params['gallery_images'] ?? []), JSON_UNESCAPED_UNICODE),
            'tags' => json_encode(self::normalizeStringList($params['tags'] ?? []), JSON_UNESCAPED_UNICODE),
            'attendance_status' => trim((string)($params['attendance_status'] ?? 'off')),
            'review_status' => trim((string)($params['review_status'] ?? 'draft')),
            'is_new' => empty($params['is_new']) ? 0 : 1,
            'is_popular' => empty($params['is_popular']) ? 0 : 1,
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'sort' => max((int)($params['sort'] ?? 0), 0),
            'update_time' => time(),
        ];
    }

    private static function normalizeStringList(array $items): array
    {
        $normalized = [];
        foreach ($items as $item) {
            $value = trim((string)$item);
            if ($value !== '') {
                $normalized[] = $value;
            }
        }

        return $normalized;
    }

    private static function dictTextMap(array $types): array
    {
        $rows = DictData::whereIn('type_value', $types)
            ->where(['status' => 1])
            ->select()
            ->toArray();

        $map = [];
        foreach ($rows as $row) {
            $map[(string)$row['type_value']][(string)$row['value']] = (string)$row['name'];
        }

        return $map;
    }

    private static function attendanceStatusText(string $status): string
    {
        return [
            'working' => '出勤中',
            'off' => '休息',
            'scheduled' => '待出勤',
        ][$status] ?? $status;
    }

    private static function reviewStatusText(string $status): string
    {
        return [
            'draft' => '草稿',
            'reviewing' => '审核中',
            'approved' => '审核通过',
            'rejected' => '审核驳回',
        ][$status] ?? $status;
    }

    private static function smokingStatusText(string $status): string
    {
        return [
            'unknown' => '未填写',
            'none' => '不抽烟',
            'sometimes' => '偶尔抽烟',
            'regular' => '抽烟',
        ][$status] ?? $status;
    }

    private static function drinkingStatusText(string $status): string
    {
        return [
            'unknown' => '未填写',
            'none' => '不喝酒',
            'sometimes' => '偶尔喝酒',
            'regular' => '喝酒',
        ][$status] ?? $status;
    }
}
