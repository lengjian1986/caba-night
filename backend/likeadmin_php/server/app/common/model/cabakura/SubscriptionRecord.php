<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class SubscriptionRecord extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_subscription_record';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('member_no|nickname|plan_name|transaction_no', 'like', '%' . $value . '%');
        }
    }

    public function searchPayStatusAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('pay_status', '=', $value);
        }
    }
}
