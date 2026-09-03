<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class Area extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_area';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('name|kana|prefecture|city|code', 'like', '%' . $value . '%');
        }
    }

    public function searchLevelAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('level', '=', (int)$value);
        }
    }

    public function searchParentIdAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('parent_id', '=', (int)$value);
        }
    }

    public function searchIsShowAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('is_show', '=', (int)$value);
        }
    }

    public function searchIsRecommendedAttr($query, $value, $data)
    {
        if ($value !== '' && $value !== null) {
            $query->where('is_recommended', '=', (int)$value);
        }
    }
}
