<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class Member extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_member';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('member_no|nickname|real_name|mobile|email', 'like', '%' . $value . '%');
        }
    }

    public function searchIdentityStatusAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('identity_status', '=', $value);
        }
    }

    public function getMobileMaskedAttr($value, $data): string
    {
        $mobile = (string)($data['mobile'] ?? '');
        if (strlen($mobile) < 8) {
            return $mobile;
        }
        return substr($mobile, 0, 3) . '-****-' . substr($mobile, -4);
    }
}
