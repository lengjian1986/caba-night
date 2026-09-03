<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\SupportLogic;

class SupportController extends BaseAdminController
{
    public function tickets()
    {
        return $this->data(SupportLogic::tickets($this->request->get()));
    }

    public function updateStatus()
    {
        try {
            SupportLogic::updateStatus($this->request->post());
            return $this->success('ステータスを更新しました', [], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function messages()
    {
        return $this->data(SupportLogic::messages($this->request->get()));
    }

    public function reply()
    {
        try {
            SupportLogic::reply($this->request->post());
            return $this->success('返信しました', [], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }
}
