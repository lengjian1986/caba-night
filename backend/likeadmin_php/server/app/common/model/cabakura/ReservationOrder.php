<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class ReservationOrder extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_order';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('order_no|member_name|shop_name|cast_name', 'like', '%' . $value . '%');
        }
    }

    public function searchStatusAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('status', '=', $value);
        }
    }

    public function getVisitTimeAttr($value): string
    {
        if (!$value) {
            return '';
        }

        return (new \DateTimeImmutable('@' . (int)$value))
            ->setTimezone(new \DateTimeZone('Asia/Tokyo'))
            ->format('Y-m-d H:i');
    }
}
