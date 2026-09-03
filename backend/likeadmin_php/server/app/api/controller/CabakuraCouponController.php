<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraCouponLogic;

class CabakuraCouponController extends BaseApiController
{
    public function lists()
    {
        return $this->success('クーポン一覧を取得しました', [
            'lists' => CabakuraCouponLogic::lists($this->userId),
        ]);
    }
}
