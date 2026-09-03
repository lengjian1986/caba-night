<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class MemberDeleteRecord extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_member_delete_record';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('member_no|nickname|mobile|reason', 'like', '%' . $value . '%');
        }
    }

    public function searchStatusAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('status', '=', $value);
        }
    }
}
