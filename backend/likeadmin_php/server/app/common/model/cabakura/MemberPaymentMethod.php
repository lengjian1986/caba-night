<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class MemberPaymentMethod extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_member_payment_method';
    protected $deleteTime = 'delete_time';
}
