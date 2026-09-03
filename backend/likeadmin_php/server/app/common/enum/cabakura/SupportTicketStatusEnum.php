<?php

declare(strict_types=1);

namespace app\common\enum\cabakura;

class SupportTicketStatusEnum
{
    public const OPEN = 'open';
    public const PENDING_OPERATOR = 'pending_operator';
    public const PENDING_USER = 'pending_user';
    public const RESOLVED = 'resolved';
    public const CLOSED = 'closed';

    public static function labels(): array
    {
        return [
            self::OPEN => '未対応',
            self::PENDING_OPERATOR => '対応中',
            self::PENDING_USER => '対応中',
            self::RESOLVED => '対応済み',
            self::CLOSED => '対応済み',
        ];
    }

    public static function label(string $status): string
    {
        return self::labels()[$status] ?? $status;
    }
}
