<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\AnswerSettingLogic;

class AnswerSettingController extends BaseAdminController
{
    public function fields()
    {
        return $this->data(AnswerSettingLogic::fields());
    }

    public function saveOption()
    {
        try {
            $id = AnswerSettingLogic::saveOption($this->request->post());
            return $this->success('选项已保存', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function deleteOption()
    {
        try {
            AnswerSettingLogic::deleteOption($this->request->post());
            return $this->success('选项已删除', [], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }
}
