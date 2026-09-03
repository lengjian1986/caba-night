<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\AreaLogic;

class AreaController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(AreaLogic::lists($this->request->get()));
    }

    public function save()
    {
        $id = AreaLogic::save($this->request->post());
        return $this->success('エリアを保存しました', ['id' => $id], 1, 1);
    }

    public function switchShow()
    {
        AreaLogic::switchShow($this->request->post());
        return $this->success('表示状態を更新しました', [], 1, 1);
    }

    public function switchRecommended()
    {
        AreaLogic::switchRecommended($this->request->post());
        return $this->success('おすすめ状態を更新しました', [], 1, 1);
    }

    public function delete()
    {
        AreaLogic::delete($this->request->post());
        return $this->success('エリアを削除しました', [], 1, 1);
    }
}
