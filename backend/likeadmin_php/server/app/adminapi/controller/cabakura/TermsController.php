<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\TermsLogic;

class TermsController extends BaseAdminController
{
    public function lists() { return $this->data(TermsLogic::lists($this->request->get())); }

    public function save()
    {
        try {
            $id = TermsLogic::save($this->request->post());
            return $this->success('利用規約を保存しました', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function switchShow()
    {
        try {
            TermsLogic::switchShow($this->request->post());
            return $this->success('表示状態を更新しました');
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }
}
