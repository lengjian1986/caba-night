<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class ShopManager extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_shop_manager';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('name|mobile', 'like', '%' . $value . '%');
        }
    }
}
