<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\model\cabakura\Coupon;
use app\common\model\cabakura\MemberCoupon;

class CabakuraCouponLogic
{
    public static function lists(int $userId): array
    {
        if ($userId <= 0) return [];
        $items = MemberCoupon::where('user_id', $userId)->field('id,coupon_id,coupon_code,status,received_time,expire_time,used_time')->order('status asc,id desc')->select()->toArray();
        foreach ($items as &$item) {
            $coupon = Coupon::findOrEmpty((int)$item['coupon_id']);
            $item['name'] = $coupon->isEmpty() ? $item['coupon_code'] : (string)$coupon->name;
            $item['description'] = $coupon->isEmpty() ? '' : (string)$coupon->description;
            $item['logo_image'] = $coupon->isEmpty() ? '' : (string)$coupon->logo_image;
            $item['discount_type'] = $coupon->isEmpty() ? 'fixed' : (string)$coupon->discount_type;
            $item['discount_value'] = $coupon->isEmpty() ? 0 : (int)$coupon->discount_value;
            $item['received_time_text'] = self::formatTime((int)$item['received_time']);
            $item['expire_time_text'] = self::formatTime((int)$item['expire_time']);
            if ($item['status'] === 'available' && (int)$item['expire_time'] > 0 && (int)$item['expire_time'] < time()) $item['status'] = 'expired';
        }
        return $items;
    }

    private static function formatTime(int $time): string { return $time > 0 ? date('Y-m-d', $time) : ''; }
}
