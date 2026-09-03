<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\ShopLogic;

class ShopController extends BaseAdminController
{
    public function saveDraft()
    {
        $id = ShopLogic::saveDraft($this->request->post());
        return $this->success('草稿已保存', ['id' => $id], 1, 1);
    }

    public function submitReview()
    {
        $params = $this->request->post();
        if (empty($params['name']) || empty($params['license_no']) || empty($params['license_files'])) {
            return $this->fail('请填写店铺名、许可证号并上传营业执照');
        }
        $id = ShopLogic::submitReview($params);
        return $this->success('已提交审核', ['id' => $id], 1, 1);
    }

    public function updateInfo()
    {
        $params = $this->request->post();
        if (empty($params['id'])) {
            return $this->fail('缺少店铺ID');
        }
        if (empty($params['name']) || empty($params['license_no'])) {
            return $this->fail('请填写店铺名和许可证号');
        }

        ShopLogic::updateInfo($params);
        return $this->success('店铺资料已保存', [], 1, 1);
    }

    public function switchRecommended()
    {
        ShopLogic::switchRecommended($this->request->post());
        return $this->success('人気店舗表示を更新しました', [], 1, 1);
    }

    public function lists()
    {
        return $this->data(ShopLogic::lists($this->request->get()));
    }

    public function detail()
    {
        return $this->data(ShopLogic::detail((int)$this->request->get('id')));
    }

    public function approve()
    {
        ShopLogic::approve($this->request->post());
        return $this->success('审核已通过', [], 1, 1);
    }

    public function reject()
    {
        $params = $this->request->post();
        if (empty($params['reason'])) {
            return $this->fail('请填写驳回原因');
        }
        ShopLogic::reject($params);
        return $this->success('审核已驳回', [], 1, 1);
    }
}
