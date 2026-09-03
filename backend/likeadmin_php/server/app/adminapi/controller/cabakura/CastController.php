<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\CastLogic;

class CastController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(CastLogic::lists($this->request->get()));
    }

    public function saveProfile()
    {
        $params = $this->request->post();
        if (empty($params['name'])) {
            return $this->fail('请填写Cast名');
        }
        $displayFlags = [
            !empty($params['is_new']),
            !empty($params['is_popular']),
            !empty($params['is_recommended']),
        ];
        if (count(array_filter($displayFlags)) !== 1) {
            return $this->fail('表示フラグは1つだけ選択してください');
        }

        $id = CastLogic::saveProfile($params);
        return $this->success('Cast资料已保存', ['id' => $id], 1, 1);
    }

    public function switchRecommended()
    {
        CastLogic::switchRecommended($this->request->post());
        return $this->success('人気キャスト表示を更新しました', [], 1, 1);
    }

    public function switchPopular()
    {
        CastLogic::switchPopular($this->request->post());
        return $this->success('人気表示を更新しました', [], 1, 1);
    }
}
