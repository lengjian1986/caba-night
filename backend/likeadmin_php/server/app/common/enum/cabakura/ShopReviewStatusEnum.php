<?php

declare(strict_types=1);

namespace app\common\enum\cabakura;

class ShopReviewStatusEnum
{
    public const DRAFT = 'draft';
    public const SUBMITTED = 'submitted';
    public const REVIEWING = 'reviewing';
    public const APPROVED = 'approved';
    public const REJECTED = 'rejected';
    public const SUPPLEMENT_REQUIRED = 'supplement_required';
    public const SUSPENDED = 'suspended';

    public static function labels(): array
    {
        return [
            self::DRAFT => '草稿',
            self::SUBMITTED => '待审核',
            self::REVIEWING => '审核中',
            self::APPROVED => '审核通过',
            self::REJECTED => '审核驳回',
            self::SUPPLEMENT_REQUIRED => '需补充资料',
            self::SUSPENDED => '暂停展示',
        ];
    }

    public static function label(string $status): string
    {
        return self::labels()[$status] ?? $status;
    }
}
