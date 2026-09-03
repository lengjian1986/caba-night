<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class SupportMessage extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_support_message';
    protected $deleteTime = 'delete_time';
}
