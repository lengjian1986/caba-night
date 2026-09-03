<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\model\cabakura\CabakuraCast;
use app\common\model\cabakura\CabakuraCastSchedule;
use app\common\model\cabakura\Area;
use app\common\model\cabakura\News;
use app\common\model\cabakura\Shop;
use app\common\model\cabakura\ShopReview;
use app\common\model\dict\DictData;

class CabakuraHomeLogic
{
    public static function castSchedule(array $params): array
    {
        $castId = (int)($params['cast_id'] ?? 0);
        if ($castId <= 0 || CabakuraCast::findOrEmpty($castId)->isEmpty()) {
            return ['schedules' => []];
        }

        $today = new \DateTimeImmutable('today', new \DateTimeZone('Asia/Tokyo'));
        $defaultEnd = $today->modify('first day of +2 months')->modify('-1 day');
        $from = trim((string)($params['from'] ?? $today->format('Y-m-d')));
        $to = trim((string)($params['to'] ?? $defaultEnd->format('Y-m-d')));
        if (!self::isDate($from) || !self::isDate($to) || $from > $to) {
            return ['schedules' => []];
        }

        $schedules = CabakuraCastSchedule::where('cast_id', '=', $castId)
            ->where('work_date', '>=', $from)
            ->where('work_date', '<=', $to)
            ->field('work_date,start_time,end_time,attendance_status')
            ->order('work_date asc,start_time asc,id asc')
            ->select()
            ->toArray();

        return [
            'cast_id' => $castId,
            'from' => $from,
            'to' => $to,
            'schedules' => array_map(static function (array $schedule): array {
                return [
                    'work_date' => (string)($schedule['work_date'] ?? ''),
                    'start_time' => (string)($schedule['start_time'] ?? ''),
                    'end_time' => (string)($schedule['end_time'] ?? ''),
                    'attendance_status' => (string)($schedule['attendance_status'] ?? 'scheduled'),
                ];
            }, $schedules),
        ];
    }

    public static function resolveLocation(array $params): array
    {
        $latitude = (float)($params['latitude'] ?? 0);
        $longitude = (float)($params['longitude'] ?? 0);
        if ($latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180) {
            return ['area' => '', 'distance_km' => null];
        }

        $availableAreaIndex = self::availableShopAreaIndex();
        $areas = Area::where('is_show', '=', 1)
            ->where('latitude', '>', 0)
            ->where('longitude', '>', 0)
            ->field('id,name,prefecture,latitude,longitude')
            ->select()
            ->toArray();
        $nearest = null;
        foreach ($areas as $area) {
            $areaName = (string)($area['name'] ?: $area['prefecture']);
            if (!isset($availableAreaIndex['ids'][(int)$area['id']])) {
                continue;
            }
            $distance = self::distanceInKm(
                $latitude,
                $longitude,
                (float)$area['latitude'],
                (float)$area['longitude']
            );
            if ($nearest === null || $distance < $nearest['distance_km']) {
                $nearest = [
                    'area' => $areaName,
                    'distance_km' => round($distance, 2),
                ];
            }
        }

        return $nearest ?? ['area' => '', 'distance_km' => null];
    }

    private static function distanceInKm(
        float $latitude,
        float $longitude,
        float $targetLatitude,
        float $targetLongitude
    ): float {
        $earthRadius = 6371.0;
        $latDelta = deg2rad($targetLatitude - $latitude);
        $lonDelta = deg2rad($targetLongitude - $longitude);
        $a = sin($latDelta / 2) ** 2
            + cos(deg2rad($latitude))
            * cos(deg2rad($targetLatitude))
            * sin($lonDelta / 2) ** 2;
        return $earthRadius * 2 * asin(min(1, sqrt($a)));
    }

    private static function isDate(string $date): bool
    {
        $parsed = \DateTimeImmutable::createFromFormat('!Y-m-d', $date);
        return $parsed !== false && $parsed->format('Y-m-d') === $date;
    }

    public static function index(array $params): array
    {
        $keyword = trim((string)($params['keyword'] ?? ''));
        $area = trim((string)($params['area'] ?? ''));
        $attendanceStatus = trim((string)($params['attendance_status'] ?? ''));
        $sort = trim((string)($params['sort'] ?? 'recommended'));
        $shopFilter = trim((string)($params['shop_filter'] ?? ''));
        $castSort = trim((string)($params['cast_sort'] ?? 'recommended'));
        $strictSearch = !empty($params['strict_search']);

        $data = [
            'shops' => self::shops($keyword, $area, $sort, $shopFilter, $strictSearch),
            'casts' => self::casts($keyword, $area, $attendanceStatus, $castSort),
            'plans' => self::plans($keyword, $area),
            'news' => self::news($keyword),
            'areas' => self::areas(),
        ];

        if (!empty($params['area_tree'])) {
            $data['area_tree'] = self::areaTree();
        }

        return $data;
    }

    public static function detail(array $params): array
    {
        $shopId = (int)($params['shop_id'] ?? $params['id'] ?? 0);
        if ($shopId <= 0) {
            return [];
        }

        $shop = Shop::findOrEmpty($shopId);
        if ($shop->isEmpty()) {
            return [];
        }

        $shopData = $shop->toArray();
        $images = array_values(array_filter(array_map(
            fn($image) => self::imageUrl((string)$image),
            is_array($shopData['shop_images'] ?? null) ? $shopData['shop_images'] : []
        )));
        if (empty($images) && !empty($shopData['logo_image'])) {
            $images[] = self::imageUrl((string)$shopData['logo_image']);
        }
        $packageSets = $shopData['package_sets'] ?? [];
        if (is_string($packageSets)) {
            $decodedPackageSets = json_decode($packageSets, true);
            $packageSets = is_array($decodedPackageSets) ? $decodedPackageSets : [];
        }
        $tagNameMap = self::dictValueNameMap('cbk_shop_plan_tag');
        foreach ($packageSets as &$packageSet) {
            if (!is_array($packageSet)) {
                continue;
            }
            $tags = is_array($packageSet['tags'] ?? null)
                ? array_values(array_filter($packageSet['tags']))
                : [];
            $packageSet['tags'] = self::displayTags($tags, $tagNameMap);
        }
        unset($packageSet);

        $casts = CabakuraCast::where(['shop_id' => $shopId])
            ->field('id,name,age,height,style,blood_type,birthplace,hobby,attendance_frequency,preferred_male_type,smoking_drinking,profile,main_image,gallery_images,attendance_status,rating,favorite_count,tags,is_new,is_popular,is_recommended,sort')
            ->order('is_recommended desc,sort desc,id desc')
            ->limit(50)
            ->select()
            ->toArray();
        $smokingDrinkingNameMap = self::dictValueNameMap('cbk_cast_smoking_drinking');
        $castReviewMap = self::castReviewsByCastIds(array_map(
            static fn(array $cast): int => (int)($cast['id'] ?? 0),
            $casts
        ));
        $reviews = ShopReview::where(['shop_id' => $shopId, 'status' => 'approved'])
            ->field('id,member_name,rating,content,create_time')
            ->order('create_time desc,id desc')
            ->limit(50)
            ->select()
            ->toArray();

        return [
            'id' => $shopId,
            'name' => (string)($shopData['name'] ?? ''),
            'kana' => (string)($shopData['kana'] ?? ''),
            'area' => self::areaDisplay((string)($shopData['area'] ?? '')),
            'description' => (string)($shopData['description'] ?? ''),
            'address' => (string)($shopData['address'] ?? ''),
            'station' => (string)($shopData['station'] ?? ''),
            'business_hours' => (string)($shopData['business_hours'] ?? ''),
            'price_range' => (string)($shopData['price_range'] ?? ''),
            'business_status' => (string)($shopData['business_status'] ?? ''),
            'booking_enabled' => !empty($shopData['booking_enabled']),
            'rating' => '4.8',
            'review_count' => count($reviews),
            'shop_images' => $images,
            'package_sets' => is_array($packageSets) ? $packageSets : [],
            'casts' => array_map(function (array $cast) use ($shopData, $shopId, $smokingDrinkingNameMap, $castReviewMap): array {
                $status = (string)($cast['attendance_status'] ?? 'off');
                $smokingDrinking = (string)($cast['smoking_drinking'] ?? '');
                return [
                    'id' => (int)$cast['id'],
                    'shop_id' => $shopId,
                    'name' => (string)$cast['name'],
                    'age' => (int)($cast['age'] ?? 0),
                    'height' => (int)($cast['height'] ?? 0),
                    'style' => (string)($cast['style'] ?? ''),
                    'blood_type' => (string)($cast['blood_type'] ?? ''),
                    'birthplace' => (string)($cast['birthplace'] ?? ''),
                    'hobby' => (string)($cast['hobby'] ?? ''),
                    'attendance_frequency' => (string)($cast['attendance_frequency'] ?? ''),
                    'preferred_male_type' => (string)($cast['preferred_male_type'] ?? ''),
                    'smoking_drinking' => $smokingDrinkingNameMap[$smokingDrinking] ?? $smokingDrinking,
                    'profile' => (string)($cast['profile'] ?? ''),
                    'gallery_images' => array_values(array_filter(array_map(
                        fn($image) => self::imageUrl((string)$image),
                        is_array($cast['gallery_images'] ?? null) ? $cast['gallery_images'] : []
                    ))),
                    'reviews' => $castReviewMap[(int)($cast['id'] ?? 0)] ?? [],
                    'shop' => (string)($shopData['name'] ?? ''),
                    'area' => self::areaDisplay((string)($cast['area'] ?? $shopData['area'] ?? '')),
                    'shop_image' => self::imageUrl((string)(
                        (is_array($shopData['shop_images'] ?? null)
                            ? ($shopData['shop_images'][0] ?? '')
                            : '') ?: ($shopData['logo_image'] ?? '')
                    )),
                    'status' => self::attendanceStatusText($status),
                    'attendance_status' => $status,
                    'image' => self::imageUrl((string)($cast['main_image'] ?? '')),
                    'rating' => (string)($cast['rating'] ?? ''),
                    'favorite_count' => (int)($cast['favorite_count'] ?? 0),
                    'tags' => is_array($cast['tags'] ?? null) ? $cast['tags'] : [],
                    'is_new' => (int)($cast['is_new'] ?? 0),
                    'is_popular' => (int)($cast['is_popular'] ?? 0),
                    'is_recommended' => (int)($cast['is_recommended'] ?? 0),
                ];
            }, $casts),
            'reviews' => array_map(static function (array $review): array {
                $reviewTime = $review['create_time'] ?? '';
                $reviewDate = is_numeric($reviewTime)
                    ? date('Y.m.d', (int)$reviewTime)
                    : ($reviewTime !== '' ? date('Y.m.d', strtotime((string)$reviewTime)) : '');
                return [
                    'id' => (int)$review['id'],
                    'name' => (string)($review['member_name'] ?? ''),
                    'rating' => (string)($review['rating'] ?? ''),
                    'content' => (string)($review['content'] ?? ''),
                    'date' => $reviewDate,
                ];
            }, $reviews),
        ];
    }

    private static function shops(
        string $keyword,
        string $area,
        string $sort = 'recommended',
        string $shopFilter = '',
        bool $strictSearch = false
    ): array
    {
        $query = Shop::field('id,name,kana,area,description,keywords,address,station,business_hours,price_range,package_sets,tags,logo_image,shop_images,business_status,is_recommended,booking_enabled,review_status');

        if ($keyword !== '') {
            $terms = self::keywordTerms($keyword);
            $castShopIds = CabakuraCast::where(function ($castQuery) use ($terms) {
                foreach ($terms as $index => $term) {
                    $pattern = '%' . $term . '%';
                    if ($index === 0) {
                        $castQuery->where('name|kana|style|hobby|profile|tags', 'like', $pattern);
                    } else {
                        $castQuery->whereOr('name|kana|style|hobby|profile|tags', 'like', $pattern);
                    }
                }
            })->column('shop_id');
            $query->where(function ($shopQuery) use ($terms, $castShopIds) {
                foreach ($terms as $index => $term) {
                    $pattern = '%' . $term . '%';
                    if ($index === 0) {
                        $shopQuery->where(
                            'name|kana|area|description|keywords|address|station|business_hours|tags|package_sets',
                            'like',
                            $pattern
                        );
                    } else {
                        $shopQuery->whereOr(
                            'name|kana|area|description|keywords|address|station|business_hours|tags|package_sets',
                            'like',
                            $pattern
                        );
                    }
                }
                if (!empty($castShopIds)) {
                    $shopQuery->whereOr('id', 'in', $castShopIds);
                }
            });
        }
        if ($area !== '') {
            $shopIds = self::shopIdsByArea($area);
            if (empty($shopIds)) {
                return [];
            }
            $query->whereIn('id', $shopIds);
        }
        if ($shopFilter === 'open') {
            $query->where('business_status', '=', '営業中');
        } elseif ($shopFilter === 'booking') {
            $query->where('booking_enabled', '=', 1);
        } elseif ($shopFilter === 'discount') {
            $query->where(function ($filterQuery) {
                $filterQuery->where('tags', 'like', '%割引%')
                    ->whereOr('tags', 'like', '%OFF%')
                    ->whereOr('package_sets', 'like', '%割引%')
                    ->whereOr('package_sets', 'like', '%OFF%');
            });
        }

        $order = match ($sort) {
            'popular' => 'booking_enabled desc,is_recommended desc,id desc',
            'distance' => 'id asc',
            'rating' => 'is_recommended desc,booking_enabled desc,id desc',
            'updated' => 'update_time desc,id desc',
            default => 'is_recommended desc,booking_enabled desc,id desc',
        };
        $rows = $query
            ->order($order)
            ->limit(50)
            ->select()
            ->toArray();

        $isSearchFallback = false;
        if ($keyword !== '' && empty($rows) && !$strictSearch) {
            $fallbackQuery = Shop::field('id,name,kana,area,description,keywords,address,station,business_hours,price_range,package_sets,tags,logo_image,shop_images,business_status,is_recommended,booking_enabled,review_status')
                ->where('is_recommended', '=', 1);
            if ($area !== '') {
                $shopIds = self::shopIdsByArea($area);
                if (empty($shopIds)) {
                    return [];
                }
                $fallbackQuery->whereIn('id', $shopIds);
            }
            if ($shopFilter === 'open') {
                $fallbackQuery->where('business_status', '=', '営業中');
            } elseif ($shopFilter === 'booking') {
                $fallbackQuery->where('booking_enabled', '=', 1);
            } elseif ($shopFilter === 'discount') {
                $fallbackQuery->where(function ($filterQuery) {
                    $filterQuery->where('tags', 'like', '%割引%')
                        ->whereOr('tags', 'like', '%OFF%')
                        ->whereOr('package_sets', 'like', '%割引%')
                        ->whereOr('package_sets', 'like', '%OFF%');
                });
            }
            $rows = $fallbackQuery
                ->order($order)
                ->limit(50)
                ->select()
                ->toArray();
            $isSearchFallback = !empty($rows);
        }

        return array_map(function ($item) use ($isSearchFallback) {
            $images = is_array($item['shop_images'] ?? null) ? $item['shop_images'] : [];
            $image = !empty($images) ? (string)$images[0] : '';
            if ($image === '') {
                $image = (string)($item['logo_image'] ?? '');
            }
            $shopImages = array_values(array_filter(array_map(
                fn($shopImage) => self::imageUrl((string)$shopImage),
                $images
            )));
            $packageSets = $item['package_sets'] ?? [];
            if (is_string($packageSets)) {
                $decodedPackageSets = json_decode($packageSets, true);
                $packageSets = is_array($decodedPackageSets) ? $decodedPackageSets : [];
            }

            return [
                'id' => (int)$item['id'],
                'name' => (string)$item['name'],
                'area' => self::areaDisplay((string)$item['area']),
                'description' => (string)($item['description'] ?? ''),
                'address' => (string)($item['address'] ?? ''),
                'station' => (string)($item['station'] ?? ''),
                'business_hours' => (string)($item['business_hours'] ?? ''),
                'price' => (string)($item['price_range'] ?: ''),
                'rating' => '4.8',
                'image' => self::imageUrl($image),
                'shop_images' => $shopImages,
                'package_sets' => is_array($packageSets) ? $packageSets : [],
                'tags' => is_array($item['tags'] ?? null) ? $item['tags'] : [],
                'business_status' => (string)($item['business_status'] ?? ''),
                'is_recommended' => (int)($item['is_recommended'] ?? 0),
                'booking_enabled' => !empty($item['booking_enabled']),
                'is_search_fallback' => $isSearchFallback,
            ];
        }, $rows);
    }

    private static function casts(
        string $keyword,
        string $area,
        string $attendanceStatus = '',
        string $castSort = 'recommended'
    ): array
    {
        $query = CabakuraCast::field('id,shop_id,name,kana,age,height,style,blood_type,birthplace,hobby,attendance_frequency,preferred_male_type,smoking_drinking,profile,tags,main_image,gallery_images,attendance_status,review_status,rating,favorite_count,is_new,is_popular,is_recommended,sort');

        if ($keyword !== '') {
            $pattern = '%' . $keyword . '%';
            $castShopIds = Shop::where(
                'name|kana|area|description|address|station|business_hours|tags',
                'like',
                $pattern
            )->column('id');
            $query->where(function ($castQuery) use ($pattern, $castShopIds) {
                $castQuery->where(
                    'name|kana|style|blood_type|birthplace|hobby|attendance_frequency|preferred_male_type|smoking_drinking|profile|tags|measurements',
                    'like',
                    $pattern
                );
                if (!empty($castShopIds)) {
                    $castQuery->whereOr('shop_id', 'in', $castShopIds);
                }
            });
        }
        if ($area !== '') {
            $shopIds = self::shopIdsByArea($area);
            if (empty($shopIds)) {
                return [];
            }
            $query->whereIn('shop_id', $shopIds);
        }
        $castOrder = match ($castSort) {
            'popular' => 'favorite_count desc,is_recommended desc,sort desc,id desc',
            'rating' => 'rating desc,favorite_count desc,sort desc,id desc',
            'updated' => 'update_time desc,id desc',
            default => 'is_recommended desc,sort desc,id desc',
        };
        $rows = $query
            ->orderRaw("FIELD(attendance_status, 'working', 'scheduled', 'off') ASC, {$castOrder}")
            ->limit(200)
            ->select()
            ->toArray();

        $attendanceByCast = [];
        foreach ($rows as $item) {
            $castId = (int)($item['id'] ?? 0);
            if ($castId > 0) {
                $status = (string)($item['attendance_status'] ?? 'off');
                $attendanceByCast[$castId] = in_array($status, ['working', 'scheduled', 'off'], true)
                    ? $status
                    : 'off';
            }
        }

        $rows = array_values(array_filter($rows, function ($item) use ($attendanceStatus, $attendanceByCast) {
            $status = $attendanceByCast[(int)($item['id'] ?? 0)] ?? 'off';
            return !in_array($attendanceStatus, ['working', 'scheduled', 'off'], true)
                || $status === $attendanceStatus;
        }));
        $rows = array_slice($rows, 0, 20);
        $smokingDrinkingNameMap = self::dictValueNameMap('cbk_cast_smoking_drinking');
        $castReviewMap = self::castReviewsByCastIds(array_map(
            static fn(array $item): int => (int)($item['id'] ?? 0),
            $rows
        ));

        $shopIds = array_values(array_unique(array_filter(array_map(fn($item) => (int)$item['shop_id'], $rows))));
        $shopNames = [];
        $shopAreas = [];
        $shopImages = [];
        $shopStatuses = [];
        if (!empty($shopIds)) {
            $shopRows = Shop::whereIn('id', $shopIds)
                ->field('id,name,area,shop_images,business_status')
                ->select()
                ->toArray();
            foreach ($shopRows as $shopRow) {
                $shopId = (int)($shopRow['id'] ?? 0);
                $shopNames[$shopId] = (string)($shopRow['name'] ?? '');
                $shopAreas[$shopId] = (string)($shopRow['area'] ?? '');
                $images = is_array($shopRow['shop_images'] ?? null) ? $shopRow['shop_images'] : [];
                $shopImages[$shopId] = self::imageUrl((string)($images[0] ?? ''));
                $shopStatuses[$shopId] = (string)($shopRow['business_status'] ?? '');
            }
        }

        return array_map(function ($item) use ($shopNames, $shopAreas, $shopImages, $shopStatuses, $attendanceByCast, $smokingDrinkingNameMap, $castReviewMap) {
            $shopId = (int)($item['shop_id'] ?? 0);
            $favoriteCount = (int)($item['favorite_count'] ?? 0);
            $status = $attendanceByCast[(int)($item['id'] ?? 0)] ?? 'off';
            $smokingDrinking = (string)($item['smoking_drinking'] ?? '');

            return [
                'id' => (int)$item['id'],
                'shop_id' => $shopId,
                'name' => (string)$item['name'],
                'age' => (int)($item['age'] ?? 0),
                'shop' => (string)($shopNames[$shopId] ?? ''),
                'area' => self::areaDisplay((string)($shopAreas[$shopId] ?? '')),
                'shop_image' => (string)($shopImages[$shopId] ?? ''),
                'shop_business_status' => (string)($shopStatuses[$shopId] ?? ''),
                'status' => self::attendanceStatusText($status),
                'image' => self::imageUrl((string)($item['main_image'] ?? '')),
                'rating' => (string)($item['rating'] ?? ''),
                'height' => (int)($item['height'] ?? 0),
                'style' => (string)($item['style'] ?? ''),
                'blood_type' => (string)($item['blood_type'] ?? ''),
                'birthplace' => (string)($item['birthplace'] ?? ''),
                'hobby' => (string)($item['hobby'] ?? ''),
                'attendance_frequency' => (string)($item['attendance_frequency'] ?? ''),
                'preferred_male_type' => (string)($item['preferred_male_type'] ?? ''),
                'smoking_drinking' => $smokingDrinkingNameMap[$smokingDrinking] ?? $smokingDrinking,
                'profile' => (string)($item['profile'] ?? ''),
                'gallery_images' => array_values(array_filter(array_map(
                    fn($image) => self::imageUrl((string)$image),
                    is_array($item['gallery_images'] ?? null) ? $item['gallery_images'] : []
                ))),
                'reviews' => $castReviewMap[(int)($item['id'] ?? 0)] ?? [],
                'favorite_count' => $favoriteCount,
                'review_count' => max((int)floor($favoriteCount / 4), 12),
                'tags' => is_array($item['tags'] ?? null) ? $item['tags'] : [],
                'is_new' => (int)($item['is_new'] ?? 0),
                'is_popular' => (int)($item['is_popular'] ?? 0),
                'is_recommended' => (int)($item['is_recommended'] ?? 0),
            ];
        }, $rows);
    }

    private static function castReviewsByCastIds(array $castIds): array
    {
        $castIds = array_values(array_filter(array_map('intval', $castIds)));
        if (empty($castIds)) {
            return [];
        }

        $reviews = ShopReview::whereIn('cast_id', $castIds)
            ->where(['status' => 'approved'])
            ->field('id,cast_id,member_name,rating,content,create_time')
            ->order('create_time desc,id desc')
            ->select()
            ->toArray();
        $result = [];
        foreach ($reviews as $review) {
            $castId = (int)($review['cast_id'] ?? 0);
            if ($castId <= 0) {
                continue;
            }
            $reviewTime = $review['create_time'] ?? '';
            $result[$castId][] = [
                'id' => (int)($review['id'] ?? 0),
                'name' => (string)($review['member_name'] ?? ''),
                'rating' => (string)($review['rating'] ?? ''),
                'content' => (string)($review['content'] ?? ''),
                'date' => is_numeric($reviewTime)
                    ? date('Y.m.d', (int)$reviewTime)
                    : ($reviewTime !== '' ? date('Y.m.d', strtotime((string)$reviewTime)) : ''),
            ];
        }
        return $result;
    }

    private static function todayAttendanceByCast(array $castIds): array
    {
        if (empty($castIds)) {
            return [];
        }

        $now = new \DateTimeImmutable('now', new \DateTimeZone('Asia/Tokyo'));
        $today = $now->format('Y-m-d');
        $currentMinutes = ((int)$now->format('H') * 60) + (int)$now->format('i');
        $schedules = CabakuraCastSchedule::whereIn('cast_id', $castIds)
            ->where('work_date', '=', $today)
            ->field('cast_id,start_time,end_time,attendance_status')
            ->select()
            ->toArray();

        $byCast = [];
        foreach ($schedules as $schedule) {
            $castId = (int)($schedule['cast_id'] ?? 0);
            if ($castId <= 0) {
                continue;
            }

            $start = self::timeToMinutes((string)($schedule['start_time'] ?? ''));
            $end = self::timeToMinutes((string)($schedule['end_time'] ?? ''));
            if ($start === null || $end === null) {
                continue;
            }

            $isOvernight = $end <= $start;
            $isWorking = $isOvernight
                ? $currentMinutes >= $start || $currentMinutes < $end
                : $currentMinutes >= $start && $currentMinutes < $end;
            $isScheduled = !$isWorking && (
                $isOvernight
                    ? $currentMinutes < $start && $currentMinutes >= $end
                    : $currentMinutes < $start
            );

            if ($isWorking) {
                $byCast[$castId] = 'working';
                continue;
            }
            if ($isScheduled && ($byCast[$castId] ?? 'off') !== 'working') {
                $byCast[$castId] = 'scheduled';
            } elseif (!isset($byCast[$castId])) {
                $byCast[$castId] = 'off';
            }
        }

        return $byCast;
    }

    private static function timeToMinutes(string $time): ?int
    {
        if (!preg_match('/^(\d{1,2}):(\d{2})/', trim($time), $matches)) {
            return null;
        }

        $hour = (int)$matches[1];
        $minute = (int)$matches[2];
        if ($hour > 23 || $minute > 59) {
            return null;
        }

        return ($hour * 60) + $minute;
    }

    private static function plans(string $keyword, string $area): array
    {
        $query = Shop::field('id,name,kana,area,description,keywords,tags,package_sets,shop_images,logo_image,booking_enabled');

        if ($keyword !== '') {
            $terms = self::keywordTerms($keyword);
            $query->where(function ($shopQuery) use ($terms) {
                foreach ($terms as $index => $term) {
                    $pattern = '%' . $term . '%';
                    if ($index === 0) {
                        $shopQuery->where('name|kana|area|description|keywords|tags|package_sets', 'like', $pattern);
                    } else {
                        $shopQuery->whereOr('name|kana|area|description|keywords|tags|package_sets', 'like', $pattern);
                    }
                }
            });
        }
        if ($area !== '') {
            $shopIds = self::shopIdsByArea($area);
            if (empty($shopIds)) {
                return [];
            }
            $query->whereIn('id', $shopIds);
        }

        $shops = $query
            ->order('booking_enabled desc,id desc')
            ->limit(20)
            ->select()
            ->toArray();

        $plans = [];
        $tagNameMap = self::dictValueNameMap('cbk_shop_plan_tag');
        foreach ($shops as $shop) {
            $sets = is_array($shop['package_sets'] ?? null) ? $shop['package_sets'] : [];
            $shopImages = is_array($shop['shop_images'] ?? null) ? $shop['shop_images'] : [];
            $fallbackImage = (string)($shop['logo_image'] ?? '');
            if ($fallbackImage === '' && !empty($shopImages)) {
                $fallbackImage = (string)$shopImages[0];
            }

            foreach ($sets as $index => $set) {
                if (!is_array($set)) {
                    continue;
                }
                if (empty($set['is_recommended'])) {
                    continue;
                }
                $status = (string)($set['status'] ?? 'public');
                if ($status === 'private') {
                    continue;
                }
                $name = trim((string)($set['name'] ?? ''));
                if ($name === '') {
                    continue;
                }

                $discountType = (string)($set['discount_type'] ?? 'none');
                $discountValue = (int)($set['discount_value'] ?? 0);
                $price = (int)($set['price'] ?? 0);
                $salePrice = self::planSalePrice($discountType, $discountValue, $price);
                $image = trim((string)($set['image'] ?? '')) ?: $fallbackImage;
                $tags = is_array($set['tags'] ?? null) ? array_values(array_filter($set['tags'])) : [];
                $tags = self::displayTags($tags, $tagNameMap);
                $tag = !empty($tags) ? (string)$tags[0] : self::planLabel($discountType);

                $plans[] = [
                    'id' => ((int)$shop['id']) . '-' . $index,
                    'shop_id' => (int)$shop['id'],
                    'shop_name' => (string)$shop['name'],
                    'title' => $name,
                    'tag' => $tag,
                    'tags' => $tags,
                    'label' => self::planLabel($discountType),
                    'body' => self::planBody($discountType, $discountValue, $price),
                    'price' => $price > 0 ? '¥' . number_format($price) : '',
                    'sale_price' => $salePrice > 0 ? '¥' . number_format($salePrice) : '',
                    'image' => self::imageUrl($image),
                ];

                if (count($plans) >= 10) {
                    return $plans;
                }
            }
        }

        return $plans;
    }

    private static function dictValueNameMap(string $type): array
    {
        $rows = DictData::where(['type_value' => $type, 'status' => 1])
            ->field('name,value')
            ->select()
            ->toArray();

        $map = [];
        foreach ($rows as $row) {
            $value = trim((string)($row['value'] ?? ''));
            $name = trim((string)($row['name'] ?? ''));
            if ($value !== '' && $name !== '') {
                $map[$value] = $name;
            }
        }

        return $map;
    }

    private static function displayTags(array $tags, array $nameMap): array
    {
        return array_values(array_map(function ($tag) use ($nameMap) {
            $value = (string)$tag;
            return $nameMap[$value] ?? $value;
        }, $tags));
    }

    private static function imageUrl(string $image): string
    {
        $image = trim($image);
        if ($image === '') {
            return '';
        }

        if (str_starts_with($image, 'http://') || str_starts_with($image, 'https://')) {
            $path = (string)(parse_url($image, PHP_URL_PATH) ?: '');
            return str_starts_with($path, '/uploads/') ? $path : $image;
        }

        return '/' . ltrim($image, '/');
    }

    private static function news(string $keyword): array
    {
        $query = News::field('id,logo_image,title,link,content,sort,create_time')
            ->where('is_show', '=', 1);

        if ($keyword !== '') {
            $query->where('content', 'like', '%' . $keyword . '%');
        }

        $rows = $query
            ->order('sort desc,id desc')
            ->limit(6)
            ->select();

        $news = [];
        foreach ($rows as $item) {
            $createTime = (int)$item->getData('create_time');
            $news[] = [
                'id' => (int)$item->getData('id'),
                'logo_image' => self::imageUrl((string)$item->getData('logo_image')),
                'title' => (string)$item->getData('title'),
                'link' => (string)$item->getData('link'),
                'content' => (string)$item->getData('content'),
                'created_at' => $createTime > 0 ? date('Y-m-d H:i', $createTime) : '',
                'created_timestamp' => $createTime,
            ];
        }

        return $news;
    }

    private static function areas(): array
    {
        $availableAreaIndex = self::availableShopAreaIndex();
        $rows = Area::field('id,parent_id,level,name,prefecture,city,is_recommended,sort')
            ->where('is_show', '=', 1)
            ->whereIn('level', [2, 3])
            ->order('is_recommended desc,sort desc,id desc')
            ->select()
            ->toArray();
        $rows = array_values(array_filter($rows, fn($item) => isset($availableAreaIndex['ids'][(int)$item['id']])));
        $rows = array_slice($rows, 0, 20);

        return array_map(fn($item) => [
            'id' => (int)$item['id'],
            'parent_id' => (int)($item['parent_id'] ?? 0),
            'level' => (int)($item['level'] ?? 2),
            'name' => (string)$item['name'],
            'prefecture' => (string)($item['prefecture'] ?? ''),
            'city' => (string)($item['city'] ?? ''),
            'is_recommended' => (int)($item['is_recommended'] ?? 0),
        ], $rows);
    }

    private static function areaTree(): array
    {
        $availableAreaIndex = self::availableShopAreaIndex();
        $rows = Area::field('id,parent_id,level,name,prefecture,city,is_recommended,sort')
            ->where('is_show', '=', 1)
            ->order('level asc,sort desc,code asc,id asc')
            ->select()
            ->toArray();

        $map = [];
        foreach ($rows as $row) {
            $row = [
                'id' => (int)$row['id'],
                'parent_id' => (int)($row['parent_id'] ?? 0),
                'level' => (int)($row['level'] ?? 1),
                'name' => (string)$row['name'],
                'prefecture' => (string)($row['prefecture'] ?? ''),
                'city' => (string)($row['city'] ?? ''),
                'is_recommended' => (int)($row['is_recommended'] ?? 0),
                'children' => [],
            ];
            $map[$row['id']] = $row;
        }

        $tree = [];
        foreach ($map as $id => &$row) {
            $parentId = (int)$row['parent_id'];
            if ($parentId > 0 && isset($map[$parentId])) {
                $map[$parentId]['children'][] = &$row;
                continue;
            }
            if ((int)$row['level'] === 1) {
                $tree[] = &$row;
            }
        }
        unset($row);

        return self::filterAreaTreeWithShops($tree, $availableAreaIndex['ids']);
    }

    private static function availableShopAreaIndex(): array
    {
        $shopAreas = Shop::where('review_status', '=', 'approved')
            ->where('business_status', '<>', '暂停展示')
            ->column('area');
        $areaRows = Area::where('is_show', '=', 1)
            ->field('id,parent_id,name,prefecture,city,level')
            ->select()
            ->toArray();

        $rowsById = [];
        foreach ($areaRows as $index => $row) {
            $areaRows[$index]['id'] = (int)($row['id'] ?? 0);
            $areaRows[$index]['parent_id'] = (int)($row['parent_id'] ?? 0);
            $areaRows[$index]['level'] = (int)($row['level'] ?? 1);
            if ($areaRows[$index]['id'] > 0) {
                $rowsById[$areaRows[$index]['id']] = $areaRows[$index];
            }
        }

        $areaIds = [];
        $areaNames = [];
        $addArea = static function (int $areaId) use (&$addArea, &$areaIds, &$areaNames, $rowsById): void {
            if ($areaId <= 0 || !isset($rowsById[$areaId]) || isset($areaIds[$areaId])) {
                return;
            }
            $row = $rowsById[$areaId];
            $areaIds[$areaId] = true;
            foreach (['name', 'prefecture', 'city'] as $field) {
                $value = trim((string)($row[$field] ?? ''));
                if ($value !== '') {
                    $areaNames[$value] = true;
                }
            }
            $addArea((int)($row['parent_id'] ?? 0));
        };

        foreach ($shopAreas as $shopArea) {
            $shopArea = trim((string)$shopArea);
            if ($shopArea === '') {
                continue;
            }
            $parts = preg_split('/\s+/u', $shopArea) ?: [];

            if (count($parts) >= 2) {
                $prefecturePart = trim((string)$parts[0]);
                $areaPart = trim((string)$parts[1]);
                foreach ($areaRows as $row) {
                    $level = (int)($row['level'] ?? 1);
                    $name = trim((string)($row['name'] ?? ''));
                    $prefecture = trim((string)($row['prefecture'] ?? ''));
                    $city = trim((string)($row['city'] ?? ''));
                    if (
                        $level > 1 &&
                        $prefecture === $prefecturePart &&
                        ($name === $areaPart || ($city !== '' && $city === $areaPart))
                    ) {
                        $addArea((int)$row['id']);
                    }
                    if ($level === 1 && $name === $prefecturePart) {
                        $addArea((int)$row['id']);
                    }
                }
                continue;
            }

            $matchedChildIds = [];
            foreach ($areaRows as $row) {
                $level = (int)($row['level'] ?? 1);
                $name = trim((string)($row['name'] ?? ''));
                $prefecture = trim((string)($row['prefecture'] ?? ''));
                $city = trim((string)($row['city'] ?? ''));
                if ($level === 1 && ($name === $shopArea || $prefecture === $shopArea)) {
                    $addArea((int)$row['id']);
                    continue;
                }
                if ($level > 1 && ($name === $shopArea || ($city !== '' && $city === $shopArea))) {
                    $matchedChildIds[] = (int)$row['id'];
                }
            }

            if (count($matchedChildIds) === 1) {
                $addArea($matchedChildIds[0]);
            }
        }

        return ['ids' => $areaIds, 'names' => $areaNames];
    }

    private static function filterAreaTreeWithShops(array $tree, array $availableAreaIds): array
    {
        $filtered = [];
        foreach ($tree as $area) {
            $children = self::filterAreaTreeWithShops($area['children'] ?? [], $availableAreaIds);
            $hasShop = isset($availableAreaIds[(int)$area['id']]);
            if (!$hasShop && empty($children)) {
                continue;
            }
            $area['children'] = $children;
            $filtered[] = $area;
        }

        return $filtered;
    }

    private static function attendanceStatusText(string $status): string
    {
        return [
            'working' => '出勤中',
            'scheduled' => '出勤予定',
            'off' => '休み',
        ][$status] ?? '休み';
    }

    private static function planLabel(string $discountType): string
    {
        return [
            'percent' => '割引',
            'amount' => '特別価格',
            'none' => 'おすすめ',
        ][$discountType] ?? 'おすすめ';
    }

    private static function areaKeyword(string $area): string
    {
        return preg_replace('/(都|道|府|県|市|区|町|村)$/u', '', $area) ?: $area;
    }

    private static function areaKeywords(string $area): array
    {
        $keywords = [$area, self::areaKeyword($area)];
        $rows = Area::withTrashed()
            ->field('name,prefecture,city')
            ->where('is_show', '=', 1)
            ->where('prefecture', '=', $area)
            ->select()
            ->toArray();

        $namedRows = Area::withTrashed()
            ->field('name,prefecture,city')
            ->where('is_show', '=', 1)
            ->where('name', '=', $area)
            ->select()
            ->toArray();

        foreach ($namedRows as $row) {
            $prefecture = trim((string)($row['prefecture'] ?? ''));
            if ($prefecture === '' || $prefecture === $area) {
                $rows[] = $row;
                continue;
            }
            $rows = array_merge(
                $rows,
                Area::withTrashed()
                    ->field('name,prefecture,city')
                    ->where('is_show', '=', 1)
                    ->where('prefecture', '=', $prefecture)
                    ->select()
                    ->toArray()
            );
        }

        foreach ($rows as $row) {
            foreach (['name', 'prefecture', 'city'] as $field) {
                $value = trim((string)($row[$field] ?? ''));
                if ($value === '') {
                    continue;
                }
                $keywords[] = $value;
                $keywords[] = self::areaKeyword($value);
            }
        }

        return array_values(array_unique(array_filter($keywords, fn($keyword) => mb_strlen($keyword) >= 2)));
    }

    private static function shopIdsByArea(string $area): array
    {
        $shops = Shop::field('id,area')->select()->toArray();
        $ids = [];
        $area = trim($area);
        $legacyCityNames = Area::where('is_show', '=', 1)
            ->where('prefecture', '=', $area)
            ->column('name');
        $legacyCityNames = array_values(array_filter(array_map(
            fn($name) => trim((string)$name),
            $legacyCityNames
        )));

        foreach ($shops as $shop) {
            $shopArea = trim((string)($shop['area'] ?? ''));
            if (
                $area !== '' &&
                (
                    mb_strpos($shopArea, $area) === 0 ||
                    in_array($shopArea, $legacyCityNames, true)
                )
            ) {
                $ids[] = (int)$shop['id'];
            }
        }

        return array_values(array_unique($ids));
    }

    private static function keywordTerms(string $keyword): array
    {
        $terms = preg_split('/\s+/u', trim($keyword)) ?: [];
        return array_values(array_unique(array_filter($terms, fn($term) => $term !== '')));
    }

    private static function areaDisplay(string $area): string
    {
        $area = trim($area);
        if ($area === '' || str_contains($area, ' ')) {
            return $area;
        }

        $row = Area::where('is_show', '=', 1)
            ->where('name', '=', $area)
            ->field('name,prefecture')
            ->find();
        if (!$row) {
            return $area;
        }

        $prefecture = trim((string)$row['prefecture']);
        return $prefecture !== '' ? $prefecture . ' ' . $area : $area;
    }

    private static function planBody(string $discountType, int $discountValue, int $price): string
    {
        if ($discountType === 'percent' && $discountValue > 0) {
            return $discountValue . '%OFF';
        }
        if ($discountType === 'amount' && $discountValue > 0) {
            return '¥' . number_format($discountValue);
        }
        if ($price > 0) {
            return '¥' . number_format($price);
        }
        return '予約受付中';
    }

    private static function planSalePrice(string $discountType, int $discountValue, int $price): int
    {
        if ($price <= 0) {
            return 0;
        }
        if ($discountType === 'percent' && $discountValue > 0) {
            return max((int)floor($price * (100 - min($discountValue, 100)) / 100), 0);
        }
        if ($discountType === 'amount' && $discountValue > 0) {
            return max($price - $discountValue, 0);
        }
        return $price;
    }
}
