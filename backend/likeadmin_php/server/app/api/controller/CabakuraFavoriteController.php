<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraFavoriteLogic;

class CabakuraFavoriteController extends BaseApiController
{
    public function status()
    {
        $shopId = (int)$this->request->get('shop_id/d');
        return $this->success('お気に入り状態を取得しました', [
            'favorited' => CabakuraFavoriteLogic::status($this->userId, $shopId),
        ]);
    }

    public function toggle()
    {
        $shopId = (int)$this->request->post('shop_id/d');
        return $this->success('お気に入りを更新しました', [
            'favorited' => CabakuraFavoriteLogic::toggle($this->userId, $shopId),
        ]);
    }

    public function lists()
    {
        return $this->success('お気に入り店舗を取得しました', [
            'lists' => CabakuraFavoriteLogic::lists($this->userId),
        ]);
    }

    public function castStatus()
    {
        $castId = (int)$this->request->get('cast_id/d');
        return $this->success('お気に入り状態を取得しました', [
            'favorited' => CabakuraFavoriteLogic::castStatus($this->userId, $castId),
        ]);
    }

    public function castToggle()
    {
        $castId = (int)$this->request->post('cast_id/d');
        return $this->success('お気に入りを更新しました', [
            'favorited' => CabakuraFavoriteLogic::castToggle($this->userId, $castId),
        ]);
    }

    public function castLists()
    {
        return $this->success('お気に入りキャストを取得しました', [
            'lists' => CabakuraFavoriteLogic::castLists($this->userId),
        ]);
    }
}
