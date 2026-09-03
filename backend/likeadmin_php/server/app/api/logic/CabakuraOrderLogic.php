<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\enum\cabakura\OrderStatusEnum;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\Coupon;
use app\common\model\cabakura\MemberCoupon;
use app\common\model\cabakura\ReservationOrder;

class CabakuraOrderLogic
{
    public static function lists(int $userId): array
    {
        if ($userId <= 0) {
            return [];
        }

        $orders = ReservationOrder::where('user_id', $userId)
            ->field('id,order_no,member_name,shop_name,cast_name,visit_time,people_count,amount,status,pay_status_text,remark,create_time')
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($orders as &$order) {
            $rawPaymentTime = $order['create_time'] ?? '';
            $order['payment_time_text'] = !empty($rawPaymentTime)
                ? (new \DateTimeImmutable('@' . (int)$rawPaymentTime))
                    ->setTimezone(new \DateTimeZone('Asia/Tokyo'))
                    ->format('Y-m-d H:i')
                : '';
            $order['status_text'] = OrderStatusEnum::label((string)$order['status']);
        }

        return $orders;
    }

    public static function create(array $params, int $userId = 0): array
    {
        $shopName = trim((string)($params['shop_name'] ?? ''));
        if ($shopName === '') {
            return [];
        }

        $now = time();
        $visitTime = max((int)($params['visit_time'] ?? 0), $now);
        $orderNo = 'CBK-' . date('Ymd-His', $now) . '-' . random_int(1000, 9999);
        $amount = max((int)($params['amount'] ?? 0), 0);
        $peopleCount = max((int)($params['people_count'] ?? 1), 1);
        $couponCode = strtoupper(trim((string)($params['coupon_code'] ?? '')));
        $couponRecord = null;
        if ($couponCode !== '' && $userId > 0) {
            $couponRecord = MemberCoupon::where(['user_id' => $userId, 'coupon_code' => $couponCode, 'status' => 'available'])->find();
            $coupon = $couponRecord ? Coupon::findOrEmpty((int)$couponRecord->coupon_id) : null;
            if (!$couponRecord || !$coupon || $coupon->isEmpty() || ((int)$couponRecord->expire_time > 0 && (int)$couponRecord->expire_time < $now)) {
                return [];
            }
            $discount = (string)$coupon->discount_type === 'percent'
                ? (int)floor($amount * min((int)$coupon->discount_value, 100) / 100)
                : (int)$coupon->discount_value;
            $amount = max($amount - $discount, 0);
        }
        $memberName = '';
        if ($userId > 0) {
            $member = Member::where('user_id', $userId)->field('nickname')->findOrEmpty();
            if (!$member->isEmpty()) {
                $memberName = trim((string)$member->nickname);
            }
        }
        if ($memberName === '') {
            $memberName = trim((string)($params['member_name'] ?? '')) ?: 'ゲスト';
        }

        $order = ReservationOrder::create([
            'order_no' => $orderNo,
            'user_id' => $userId,
            'member_name' => $memberName,
            'shop_name' => $shopName,
            'cast_name' => trim((string)($params['cast_name'] ?? 'なし')) ?: 'なし',
            'visit_time' => $visitTime,
            'people_count' => $peopleCount,
            'amount' => $amount,
            'status' => OrderStatusEnum::PAID,
            'pay_status_text' => '已支付',
            'remark' => trim((string)($params['remark'] ?? '')),
            'create_time' => $now,
            'update_time' => $now,
        ]);
        if ($couponRecord) {
            MemberCoupon::update(['id' => (int)$couponRecord->id, 'status' => 'used', 'used_time' => $now, 'used_order_id' => (int)$order->id, 'update_time' => $now]);
            Coupon::where('id', (int)$couponRecord->coupon_id)->inc('used_count')->update();
        }

        return [
            'id' => (int)$order->id,
            'order_no' => $orderNo,
            'status' => OrderStatusEnum::PAID,
            'pay_status_text' => '已支付',
        ];
    }
}
