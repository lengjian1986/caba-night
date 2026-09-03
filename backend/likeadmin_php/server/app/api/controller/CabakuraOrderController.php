<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraOrderLogic;

class CabakuraOrderController extends BaseApiController
{
    public array $notNeedLogin = ['create'];

    public function create()
    {
        $result = CabakuraOrderLogic::create($this->request->post(), $this->userId);
        if (empty($result)) {
            return $this->fail('订单信息不完整');
        }

        return $this->success('预约订单已创建', $result);
    }

    public function lists()
    {
        return $this->success('注文一覧を取得しました', [
            'lists' => CabakuraOrderLogic::lists($this->userId),
        ]);
    }
}
