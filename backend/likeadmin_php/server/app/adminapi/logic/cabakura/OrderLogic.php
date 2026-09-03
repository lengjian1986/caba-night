<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\enum\cabakura\OrderStatusEnum;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\ReservationOrder;

class OrderLogic
{
    public static function lists(array $params): array
    {
        $allowSearch = ['keyword', 'status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = ReservationOrder::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,user_id,order_no,member_name,shop_name,cast_name,visit_time,people_count,amount,status,pay_status_text,remark,create_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        $userIds = array_values(array_filter(array_map(
            static fn(array $item): int => (int)($item['user_id'] ?? 0),
            $lists
        )));
        $memberMap = [];
        if ($userIds) {
            $members = Member::whereIn('user_id', $userIds)
                ->field('user_id,nickname,mobile,email')
                ->select()
                ->toArray();
            foreach ($members as $member) {
                $memberMap[(int)$member['user_id']] = $member;
            }
        }

        foreach ($lists as &$item) {
            $member = $memberMap[(int)($item['user_id'] ?? 0)] ?? [];
            if (trim((string)($member['nickname'] ?? '')) !== '') {
                $item['member_name'] = (string)$member['nickname'];
            }
            $item['member_mobile'] = (string)($member['mobile'] ?? '');
            $item['member_email'] = (string)($member['email'] ?? '');
            $item['status_text'] = OrderStatusEnum::label($item['status']);
            $rawPaymentTime = $item['create_time'] ?? '';
            $item['payment_time_text'] = is_string($rawPaymentTime)
                && preg_match('/^\d{4}-\d{2}-\d{2}/', $rawPaymentTime)
                ? $rawPaymentTime
                : (!empty($rawPaymentTime)
                    ? (new \DateTimeImmutable('@' . (int)$rawPaymentTime))
                        ->setTimezone(new \DateTimeZone('Asia/Tokyo'))
                        ->format('Y-m-d H:i')
                    : '');
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function confirm(array $params): bool
    {
        if (!empty($params['id'])) {
            ReservationOrder::update([
                'id' => (int)$params['id'],
                'status' => OrderStatusEnum::CONFIRMED,
                'update_time' => time(),
            ]);
        }
        return true;
    }

    public static function reject(array $params): bool
    {
        if (!empty($params['id'])) {
            ReservationOrder::update([
                'id' => (int)$params['id'],
                'status' => OrderStatusEnum::CANCELLED,
                'update_time' => time(),
            ]);
        }
        return true;
    }

    public static function cancel(array $params): bool
    {
        if (!empty($params['id'])) {
            ReservationOrder::update([
                'id' => (int)$params['id'],
                'status' => OrderStatusEnum::CANCELLED,
                'update_time' => time(),
            ]);
        }
        return true;
    }
}
