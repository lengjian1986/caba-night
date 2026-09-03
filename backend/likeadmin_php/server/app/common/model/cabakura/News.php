<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class News extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_news';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('title|content|link', 'like', '%' . $value . '%');
        }
    }

    public function searchIsShowAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('is_show', '=', (int)$value);
        }
    }
}
