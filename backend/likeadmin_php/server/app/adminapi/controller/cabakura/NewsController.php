<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\NewsLogic;

class NewsController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(NewsLogic::lists($this->request->get()));
    }

    public function save()
    {
        try {
            $id = NewsLogic::save($this->request->post());
            return $this->success('ニュースを保存しました', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function switchShow()
    {
        if (!NewsLogic::switchShow($this->request->post())) {
            return $this->fail('ニュースを更新できませんでした');
        }

        return $this->success('表示状態を更新しました');
    }
}
