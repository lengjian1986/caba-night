<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\OrderLogic;

class OrderController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(OrderLogic::lists($this->request->get()));
    }

    public function confirm()
    {
        OrderLogic::confirm($this->request->post());
        return $this->success('预约已确认', [], 1, 1);
    }

    public function reject()
    {
        $params = $this->request->post();
        if (empty($params['reason'])) {
            return $this->fail('请填写拒绝原因');
        }
        OrderLogic::reject($params);
        return $this->success('预约已拒绝', [], 1, 1);
    }

    public function cancel()
    {
        OrderLogic::cancel($this->request->post());
        return $this->success('予約をキャンセルしました', [], 1, 1);
    }
}
