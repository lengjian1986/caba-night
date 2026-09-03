<?php

declare(strict_types=1);

namespace app\common\enum\cabakura;

class OrderStatusEnum
{
    public const REQUESTING = 'requesting';
    public const CONFIRMED = 'confirmed';
    public const UNPAID = 'unpaid';
    public const PAID = 'paid';
    public const VISITED = 'visited';
    public const COMPLETED = 'completed';
    public const CANCEL_REQUESTED = 'cancel_requested';
    public const CANCELLED = 'cancelled';
    public const REFUND_PENDING = 'refund_pending';
    public const REFUNDED = 'refunded';
    public const REFUND_FAILED = 'refund_failed';

    public static function labels(): array
    {
        return [
            self::REQUESTING => '確認待ち',
            self::CONFIRMED => '予約確定',
            self::UNPAID => '未決済',
            self::PAID => '決済済み',
            self::VISITED => '来店済み',
            self::COMPLETED => '売上確定',
            self::CANCEL_REQUESTED => 'キャンセル申請中',
            self::CANCELLED => 'キャンセル済み',
            self::REFUND_PENDING => '返金処理中',
            self::REFUNDED => '返金済み',
            self::REFUND_FAILED => '返金失敗',
        ];
    }

    public static function label(string $status): string
    {
        return self::labels()[$status] ?? $status;
    }
}
