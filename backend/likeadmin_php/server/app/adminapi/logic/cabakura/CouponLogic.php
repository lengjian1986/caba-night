<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\Coupon;
use app\common\model\cabakura\MemberCoupon;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\Shop;

class CouponLogic
{
    public static function settings(array $params): array
    {
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);
        $query = Coupon::where(function ($query) use ($params) {
            $keyword = trim((string)($params['keyword'] ?? ''));
            if ($keyword !== '') {
                $query->whereLike('code|name', '%' . $keyword . '%');
            }
            if (($params['status'] ?? '') !== '') {
                $query->where('status', $params['status']);
            }
        });
        $count = (clone $query)->count();
        $lists = $query->field('id,code,name,description,logo_image,discount_type,discount_value,min_amount,max_discount,usage_limit,used_count,per_user_limit,applicable_shop_ids,validity_days,start_time,end_time,status,sort,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)->order('sort desc,id desc')->select()->toArray();
        foreach ($lists as &$item) {
            $item['applicable_shop_ids'] = self::decodeIds($item['applicable_shop_ids'] ?? '');
            $item['start_time_text'] = self::formatTime((int)$item['start_time']);
            $item['end_time_text'] = self::formatTime((int)$item['end_time']);
            $item['discount_text'] = $item['discount_type'] === 'percent'
                ? ((int)$item['discount_value'] . '%')
                : ('¥' . number_format((int)$item['discount_value']));
        }
        return self::page($lists, $count, $pageNo, $pageSize);
    }

    public static function shops(): array
    {
        return Shop::field('id,name,area')->order('id desc')->select()->toArray();
    }

    public static function members(array $params = []): array
    {
        $query = Member::field('user_id,nickname,mobile,email');
        $keyword = trim((string)($params['keyword'] ?? ''));
        if ($keyword !== '') $query->whereLike('nickname|mobile|email', '%' . $keyword . '%');
        return $query->order('id desc')->select()->toArray();
    }

    public static function distribute(array $params): int
    {
        $couponId = (int)($params['coupon_id'] ?? 0);
        $userIds = self::normalizeIds($params['user_ids'] ?? []);
        $coupon = Coupon::findOrEmpty($couponId);
        if ($coupon->isEmpty() || !$userIds) throw new \Exception('クーポンと配布先を選択してください');
        $now = time();
        $days = max((int)$coupon->validity_days, 1);
        $count = 0;
        foreach ($userIds as $userId) {
            if (MemberCoupon::where(['coupon_id' => $couponId, 'user_id' => $userId])->find()) continue;
            MemberCoupon::create(['coupon_id' => $couponId, 'user_id' => $userId, 'coupon_code' => $coupon->code, 'status' => 'available', 'received_time' => $now, 'expire_time' => $now + ($days * 86400), 'create_time' => $now, 'update_time' => $now]);
            $count++;
        }
        return $count;
    }

    public static function save(array $params): int
    {
        $code = strtoupper(trim((string)($params['code'] ?? '')));
        $name = trim((string)($params['name'] ?? ''));
        $value = max((int)($params['discount_value'] ?? 0), 0);
        if ($code === '' || $name === '') throw new \Exception('クーポンコードとクーポン名を入力してください');
        if ($value <= 0) throw new \Exception('割引額を入力してください');
        $type = ($params['discount_type'] ?? 'fixed') === 'percent' ? 'percent' : 'fixed';
        if ($type === 'percent' && $value > 100) throw new \Exception('割引率は100以下で入力してください');
        $data = [
            'code' => $code, 'name' => $name,
            'description' => trim((string)($params['description'] ?? '')),
            'logo_image' => trim((string)($params['logo_image'] ?? '')),
            'applicable_shop_ids' => json_encode(self::normalizeIds($params['applicable_shop_ids'] ?? []), JSON_UNESCAPED_UNICODE),
            'discount_type' => $type, 'discount_value' => $value,
            'min_amount' => max((int)($params['min_amount'] ?? 0), 0),
            'max_discount' => max((int)($params['max_discount'] ?? 0), 0),
            'usage_limit' => max((int)($params['usage_limit'] ?? 1), 1),
            'validity_days' => max((int)($params['validity_days'] ?? 30), 1),
            'per_user_limit' => max((int)($params['per_user_limit'] ?? 1), 1),
            'start_time' => self::parseTime($params['start_time'] ?? 0),
            'end_time' => self::parseTime($params['end_time'] ?? 0),
            'status' => in_array(($params['status'] ?? 'draft'), ['draft', 'published', 'disabled'], true) ? $params['status'] : 'draft',
            'sort' => max((int)($params['sort'] ?? 0), 0), 'update_time' => time(),
        ];
        if (!empty($params['id'])) { $data['id'] = (int)$params['id']; Coupon::update($data); return (int)$params['id']; }
        $data['create_time'] = time();
        return (int)Coupon::create($data)->id;
    }

    public static function delete(array $params): void
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) throw new \Exception('クーポンが見つかりません');
        Coupon::destroy($id);
    }

    public static function switchStatus(array $params): void
    {
        $id = (int)($params['id'] ?? 0);
        $status = ($params['status'] ?? '') === 'published' ? 'published' : 'disabled';
        if ($id <= 0) throw new \Exception('クーポンが見つかりません');
        Coupon::update(['id' => $id, 'status' => $status, 'update_time' => time()]);
    }

    public static function usage(array $params): array { return self::memberCouponPage($params, true); }
    public static function distribution(array $params): array { return self::memberCouponPage($params, false); }

    private static function memberCouponPage(array $params, bool $usedOnly): array
    {
        $pageNo = max((int)($params['page_no'] ?? 1), 1); $pageSize = max((int)($params['page_size'] ?? 15), 1);
        $query = MemberCoupon::where(function ($query) use ($params, $usedOnly) {
            if ($usedOnly) $query->where('status', 'used');
            $keyword = trim((string)($params['keyword'] ?? ''));
            if ($keyword !== '') $query->whereLike('coupon_code', '%' . $keyword . '%');
        });
        $count = (clone $query)->count();
        $lists = $query->field('id,coupon_id,user_id,coupon_code,status,received_time,used_time,used_order_id,create_time')->limit(($pageNo - 1) * $pageSize, $pageSize)->order('id desc')->select()->toArray();
        foreach ($lists as &$item) { $item['received_time_text'] = self::formatTime((int)$item['received_time']); $item['used_time_text'] = self::formatTime((int)$item['used_time']); }
        return self::page($lists, $count, $pageNo, $pageSize);
    }

    private static function page(array $lists, int $count, int $pageNo, int $pageSize): array { return ['lists' => $lists, 'count' => $count, 'page_no' => $pageNo, 'page_size' => $pageSize]; }
    private static function parseTime($value): int { if (is_numeric($value)) return (int)$value; $time = strtotime((string)$value); return $time ?: 0; }
    private static function normalizeIds($items): array { if (!is_array($items)) return []; return array_values(array_unique(array_filter(array_map('intval', $items), static fn (int $id): bool => $id > 0))); }
    private static function decodeIds($value): array { $items = json_decode((string)$value, true); return self::normalizeIds($items ?: []); }
    private static function formatTime(int $time): string { return $time > 0 ? date('Y-m-d H:i', $time) : '-'; }
}
