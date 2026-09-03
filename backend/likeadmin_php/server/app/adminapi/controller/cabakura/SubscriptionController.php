<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\SubscriptionLogic;

class SubscriptionController extends BaseAdminController
{
    public function users()
    {
        return $this->data(SubscriptionLogic::users($this->request->get()));
    }

    public function records()
    {
        return $this->data(SubscriptionLogic::records($this->request->get()));
    }

    public function plans()
    {
        return $this->data(SubscriptionLogic::plans($this->request->get()));
    }

    public function savePlan()
    {
        try {
            $id = SubscriptionLogic::savePlan($this->request->post());
            return $this->success('サブスクPlanを保存しました', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function switchPlan()
    {
        if (!SubscriptionLogic::switchPlan($this->request->post())) {
            return $this->fail('サブスクPlanを更新できませんでした');
        }

        return $this->success('サブスクPlanを更新しました');
    }
}
