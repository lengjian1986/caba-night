<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class CabakuraCast extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_cast';
    protected $deleteTime = 'delete_time';

    public function searchShopIdAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('shop_id', '=', (int)$value);
        }
    }

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('name|kana|measurements', 'like', '%' . $value . '%');
        }
    }

    public function getGalleryImagesAttr($value): array
    {
        $images = json_decode((string)$value, true);
        return is_array($images) ? $images : [];
    }

    public function getTagsAttr($value): array
    {
        $tags = json_decode((string)$value, true);
        return is_array($tags) ? $tags : [];
    }
}
