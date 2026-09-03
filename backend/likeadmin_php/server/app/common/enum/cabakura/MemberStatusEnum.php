<?php

declare(strict_types=1);

namespace app\common\enum\cabakura;

class MemberStatusEnum
{
    public const NORMAL = 'normal';
    public const DISABLED = 'disabled';

    public static function labels(): array
    {
        return [
            self::NORMAL => '有効',
            self::DISABLED => '凍結',
        ];
    }

    public static function label(string $status): string
    {
        return self::labels()[$status] ?? $status;
    }
}
