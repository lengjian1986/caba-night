<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class SubscriptionPlan extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_subscription_plan';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('name|description', 'like', '%' . $value . '%');
        }
    }

    public function searchIsEnabledAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('is_enabled', '=', (int)$value);
        }
    }

    public function getBenefitsAttr($value): array
    {
        $benefits = json_decode((string)$value, true);
        return is_array($benefits) ? $benefits : [];
    }
}
