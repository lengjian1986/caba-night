<?php

declare(strict_types=1);

namespace app\common\enum\cabakura;

class IdentityStatusEnum
{
    public const NOT_STARTED = 'not_started';
    public const PHONE_VERIFIED = 'phone_verified';
    public const DOCUMENT_PENDING = 'document_pending';
    public const REVIEWING = 'reviewing';
    public const APPROVED = 'approved';
    public const REJECTED = 'rejected';

    public static function labels(): array
    {
        return [
            self::APPROVED => '通過',
            self::REJECTED => '拒否',
        ];
    }

    public static function label(string $status): string
    {
        return self::labels()[$status] ?? $status;
    }
}
