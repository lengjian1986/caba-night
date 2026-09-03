<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class Shop extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_shop';
    protected $deleteTime = 'delete_time';

    public function reviewLogs()
    {
        return $this->hasMany(ShopReviewLog::class, 'shop_id')->order('id asc');
    }

    public function manager()
    {
        return $this->hasOne(ShopManager::class, 'id', 'manager_id')->field('id,name,mobile');
    }

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('name|kana|area|license_no|keywords', 'like', '%' . $value . '%');
        }
    }

    public function searchReviewStatusAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('review_status', '=', $value);
        }
    }

    public function getSubmittedAtAttr($value): string
    {
        return $value ? date('Y-m-d H:i', (int)$value) : '';
    }

    public function getTagsAttr($value): array
    {
        $tags = json_decode((string)$value, true);
        return is_array($tags) ? $tags : [];
    }

    public function getPackageSetsAttr($value): array
    {
        $sets = json_decode((string)$value, true);
        return is_array($sets) ? $sets : [];
    }

    public function getShopImagesAttr($value): array
    {
        $images = json_decode((string)$value, true);
        return is_array($images) ? $images : [];
    }

    public function getLicenseFilesAttr($value): array
    {
        $files = json_decode((string)$value, true);
        return is_array($files) ? $files : [];
    }

    public function getBookingEnabledAttr($value): bool
    {
        return (bool)$value;
    }
}
