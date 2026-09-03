<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\enum\cabakura\ShopReviewStatusEnum;
use app\common\model\cabakura\Area;
use app\common\model\cabakura\Shop;

class ShopLogic
{
    public static function saveDraft(array $params): int
    {
        $data = self::shopPayload($params, ShopReviewStatusEnum::DRAFT);
        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            Shop::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $shop = Shop::create($data);
        return (int)$shop->id;
    }

    public static function submitReview(array $params): int
    {
        $data = self::shopPayload($params, ShopReviewStatusEnum::SUBMITTED);
        $data['submitted_at'] = time();
        $data['booking_enabled'] = 0;

        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            Shop::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $shop = Shop::create($data);
        return (int)$shop->id;
    }

    public static function updateInfo(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        $shop = Shop::findOrEmpty($id);
        if ($shop->isEmpty()) {
            return false;
        }

        $data = self::shopPayload($params, (string)$shop->review_status);
        $data['id'] = $id;
        $data['booking_enabled'] = (int)$shop->booking_enabled;
        $data['submitted_at'] = (int)$shop->getData('submitted_at');

        Shop::update($data);
        return true;
    }

    public static function switchRecommended(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0 || Shop::findOrEmpty($id)->isEmpty()) {
            return false;
        }

        Shop::update([
            'id' => $id,
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'update_time' => time(),
        ]);
        return true;
    }

    public static function lists(array $params): array
    {
        $allowSearch = ['keyword', 'review_status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = Shop::withSearch($search, $params)->with(['manager']);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,manager_id,name,kana,area,phone,email,license_no,keywords,review_status,business_status,is_recommended,booking_enabled,submitted_at')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['area'] = self::areaDisplay((string)($item['area'] ?? ''));
            $item['review_status_text'] = ShopReviewStatusEnum::label($item['review_status']);
            $item['manager_name'] = $item['manager']['name'] ?? '';
            $item['manager_mobile'] = $item['manager']['mobile'] ?? '';
            unset($item['manager']);
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function detail(int $id): array
    {
        $shop = Shop::with(['reviewLogs', 'manager'])->findOrEmpty($id)->toArray();
        if (empty($shop)) {
            return [];
        }

        return [
            'id' => $shop['id'],
            'manager_id' => (int)($shop['manager_id'] ?? 0),
            'manager' => $shop['manager'] ?? null,
            'name' => $shop['name'],
            'kana' => $shop['kana'],
            'area' => self::areaDisplay((string)$shop['area']),
            'phone' => $shop['phone'] ?? '',
            'email' => $shop['email'] ?? '',
            'address' => $shop['address'],
            'station' => $shop['station'],
            'business_hours' => $shop['business_hours'],
            'price_range' => $shop['price_range'],
            'description' => $shop['description'] ?? '',
            'keywords' => $shop['keywords'] ?? '',
            'tags' => $shop['tags'],
            'package_sets' => $shop['package_sets'],
            'logo_image' => $shop['logo_image'],
            'shop_images' => $shop['shop_images'],
            'business_status' => $shop['business_status'],
            'is_recommended' => (int)($shop['is_recommended'] ?? 0),
            'booking_enabled' => $shop['booking_enabled'],
            'submitted_at' => $shop['submitted_at'],
            'license' => [
                'license_no' => $shop['license_no'],
                'holder_name' => $shop['license_holder_name'],
                'expires_at' => $shop['license_expires_at'],
                'file_name' => $shop['license_file_name'],
                'files' => empty($shop['license_files']) && !empty($shop['license_file_name'])
                    ? [$shop['license_file_name']]
                    : $shop['license_files'],
            ],
            'review_status' => $shop['review_status'],
            'review_status_text' => ShopReviewStatusEnum::label($shop['review_status']),
            'review_logs' => array_map(fn($log) => [
                'action' => $log['action'],
                'operator' => $log['operator'],
                'remark' => $log['remark'],
                'time' => $log['create_time'],
            ], $shop['review_logs'] ?? []),
        ];
    }

    public static function approve(array $params): bool
    {
        if (!empty($params['id'])) {
            Shop::update([
                'id' => (int)$params['id'],
                'review_status' => ShopReviewStatusEnum::APPROVED,
                'booking_enabled' => 1,
                'update_time' => time(),
            ]);
        }
        return true;
    }

    public static function reject(array $params): bool
    {
        if (!empty($params['id'])) {
            Shop::update([
                'id' => (int)$params['id'],
                'review_status' => ShopReviewStatusEnum::REJECTED,
                'booking_enabled' => 0,
                'update_time' => time(),
            ]);
        }
        return true;
    }

    private static function areaDisplay(string $area): string
    {
        $area = trim($area);
        if ($area === '' || str_contains($area, ' ')) {
            return $area;
        }

        $row = Area::where('is_show', '=', 1)
            ->where('name', '=', $area)
            ->field('name,prefecture,city')
            ->find();
        if (!$row) {
            return $area;
        }

        $prefecture = trim((string)$row['prefecture']);
        return $prefecture !== '' ? $prefecture . ' ' . $area : $area;
    }

    private static function shopPayload(array $params, string $status): array
    {
        $licenseFiles = self::normalizeStringList($params['license_files'] ?? []);
        if (empty($licenseFiles) && !empty($params['license_file_name'])) {
            $licenseFiles = [trim((string)$params['license_file_name'])];
        }
        $name = trim((string)($params['name'] ?? ''));
        $area = trim((string)($params['area'] ?? ''));
        if ($name === '') {
            throw new \Exception('店铺名を入力してください');
        }
        if ($area === '') {
            throw new \Exception('区域を選択してください');
        }

        return [
            'name' => $name,
            'manager_id' => (int)($params['manager_id'] ?? 0),
            'kana' => trim((string)($params['kana'] ?? '')),
            'area' => $area,
            'phone' => trim((string)($params['phone'] ?? '')),
            'email' => trim((string)($params['email'] ?? '')),
            'address' => trim((string)($params['address'] ?? '')),
            'station' => trim((string)($params['station'] ?? '')),
            'business_hours' => trim((string)($params['business_hours'] ?? '')),
            'price_range' => trim((string)($params['price_range'] ?? '')),
            'description' => trim((string)($params['description'] ?? '')),
            'keywords' => self::normalizeKeywords($params['keywords'] ?? ''),
            'tags' => json_encode($params['tags'] ?? [], JSON_UNESCAPED_UNICODE),
            'package_sets' => json_encode(self::normalizePackageSets($params['package_sets'] ?? []), JSON_UNESCAPED_UNICODE),
            'logo_image' => trim((string)($params['logo_image'] ?? '')),
            'shop_images' => json_encode(self::normalizeStringList($params['shop_images'] ?? []), JSON_UNESCAPED_UNICODE),
            'license_no' => trim((string)($params['license_no'] ?? '')),
            'license_holder_name' => trim((string)($params['license_holder_name'] ?? '')),
            'license_expires_at' => trim((string)($params['license_expires_at'] ?? '')),
            'license_file_name' => $licenseFiles[0] ?? '',
            'license_files' => json_encode($licenseFiles, JSON_UNESCAPED_UNICODE),
            'review_status' => $status,
            'business_status' => trim((string)($params['business_status'] ?? '休息中')),
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'booking_enabled' => 0,
            'update_time' => time(),
        ];
    }

    private static function normalizePackageSets(array $sets): array
    {
        $normalized = [];
        foreach ($sets as $set) {
            if (!is_array($set)) {
                continue;
            }
            $name = trim((string)($set['name'] ?? ''));
            $image = trim((string)($set['image'] ?? ''));
            $castNames = self::normalizeStringList($set['cast_names'] ?? []);
            $price = max((int)($set['price'] ?? 0), 0);
            $discountType = trim((string)($set['discount_type'] ?? 'none'));
            if (!in_array($discountType, ['none', 'amount', 'percent'], true)) {
                $discountType = 'none';
            }
            $discountValue = max((int)($set['discount_value'] ?? 0), 0);
            if ($discountType === 'percent') {
                $discountValue = min($discountValue, 100);
            }
            if ($discountType === 'none') {
                $discountValue = 0;
            }
            $limitType = trim((string)($set['limit_type'] ?? 'date_range'));
            if (!in_array($limitType, ['date_range', 'usage_count'], true)) {
                $limitType = 'date_range';
            }
            $validRange = self::normalizeStringList($set['valid_range'] ?? []);
            $usageLimit = max((int)($set['usage_limit'] ?? 0), 0);
            $maxPeople = max((int)($set['max_people'] ?? 1), 1);
            $planStatus = self::normalizePlanStatus($set['status'] ?? ($set['is_show'] ?? ($set['is_enabled'] ?? 'public')));
            $isRecommended = !empty($set['is_recommended']);
            $tags = self::normalizeStringList($set['tags'] ?? []);
            $description = trim((string)($set['description'] ?? ''));

            if ($name === '' && $price === 0 && $description === '' && $image === '') {
                continue;
            }

            $normalized[] = [
                'name' => $name,
                'description' => $description,
                'image' => $image,
                'cast_names' => $castNames,
                'price' => $price,
                'discount_type' => $discountType,
                'discount_value' => $discountValue,
                'limit_type' => $limitType,
                'valid_range' => $limitType === 'date_range' ? $validRange : [],
                'usage_limit' => $limitType === 'usage_count' ? $usageLimit : 0,
                'max_people' => $maxPeople,
                'status' => $planStatus,
                'is_recommended' => $isRecommended,
                'tags' => $tags,
            ];
        }

        return $normalized;
    }

    private static function normalizePlanStatus($status): string
    {
        return in_array($status, [0, false, '0', 'private', 'hidden', 'inactive', 'off', '下架', '非公開'], true)
            ? 'private'
            : 'public';
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

    private static function normalizeKeywords($value): string
    {
        $normalized = preg_replace('/\s+/u', ' ', trim((string)$value));
        return mb_substr($normalized ?? '', 0, 500);
    }
}
