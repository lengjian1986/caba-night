<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;

class ShopReviewLog extends BaseModel
{
    protected $name = 'cbk_shop_review_log';

    public function getCreateTimeAttr($value): string
    {
        return $value ? date('Y-m-d H:i', (int)$value) : '';
    }
}
