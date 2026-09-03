<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\ShopManagerLogic;

class ShopManagerController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(ShopManagerLogic::lists($this->request->get()));
    }

    public function save()
    {
        $params = $this->request->post();
        if (empty($params['name'])) {
            return $this->fail('请填写管理者名字');
        }
        if (empty($params['mobile'])) {
            return $this->fail('请填写管理者电话');
        }
        if (empty($params['id']) && empty($params['password'])) {
            return $this->fail('请填写管理者密码');
        }

        $id = ShopManagerLogic::save($params);
        return $this->success('商铺管理者已保存', ['id' => $id], 1, 1);
    }

    public function delete()
    {
        ShopManagerLogic::delete($this->request->post());
        return $this->success('商铺管理者已删除', [], 1, 1);
    }
}
