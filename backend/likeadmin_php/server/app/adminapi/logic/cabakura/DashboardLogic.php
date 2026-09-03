<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

class DashboardLogic
{
    public static function summary(): array
    {
        return [
            'metrics' => [
                ['key' => 'today_orders', 'label' => '今日预约', 'value' => 18, 'unit' => '件'],
                ['key' => 'pending_orders', 'label' => '待确认预约', 'value' => 6, 'unit' => '件'],
                ['key' => 'pending_shop_reviews', 'label' => '待审核店铺', 'value' => 3, 'unit' => '件'],
                ['key' => 'pending_refunds', 'label' => '待退款', 'value' => 4, 'unit' => '件'],
                ['key' => 'pending_identity', 'label' => '待身份审核', 'value' => 9, 'unit' => '件'],
                ['key' => 'open_tickets', 'label' => '待处理客服', 'value' => 12, 'unit' => '件'],
            ],
            'todo' => [
                ['type' => 'shop_review', 'title' => 'LUXE TOKYO 营业执照待审核', 'time' => '2026-08-05 10:20'],
                ['type' => 'order_confirm', 'title' => '预约 #CBK-20260715-0088 等待店铺确认', 'time' => '2026-08-05 10:08'],
                ['type' => 'refund', 'title' => '取消单 CAN-20260721-0048 待退款处理', 'time' => '2026-08-05 09:52'],
            ],
        ];
    }
}
