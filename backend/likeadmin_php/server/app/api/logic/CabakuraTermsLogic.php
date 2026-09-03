<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\model\cabakura\Terms;

class CabakuraTermsLogic
{
    public static function lists(): array
    {
        return Terms::where('name', '利用規約')->where('is_show', 1)
            ->field('id,name,title,content')->order('sort desc,id desc')->select()->toArray();
    }
}
