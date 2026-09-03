<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\PushNotificationLogic;

class PushNotificationController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(PushNotificationLogic::lists($this->request->get()));
    }

    public function save()
    {
        try {
            $id = PushNotificationLogic::save($this->request->post());
            return $this->success('プッシュ通知を保存しました', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }
}
