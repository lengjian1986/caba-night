<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class CabakuraCastSchedule extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_cast_schedule';
    protected $deleteTime = 'delete_time';
}
