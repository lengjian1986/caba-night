<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\MemberLogic;

class MemberController extends BaseAdminController
{
    public function lists()
    {
        return $this->data(MemberLogic::lists($this->request->get()));
    }

    public function deleteRecords()
    {
        return $this->data(MemberLogic::deleteRecords($this->request->get()));
    }

    public function detail()
    {
        return $this->data(MemberLogic::detail((int)$this->request->get('id')));
    }

    public function updateProfile()
    {
        $params = $this->request->post();
        if (empty($params['id'])) {
            return $this->fail('缺少会员ID');
        }
        if (empty($params['nickname']) || empty($params['mobile'])) {
            return $this->fail('请填写昵称和手机号');
        }

        MemberLogic::updateProfile($params);
        return $this->success('会员资料已保存', [], 1, 1);
    }

    public function approveIdentity()
    {
        MemberLogic::approveIdentity((int)$this->request->post('id'));
        return $this->success('本人认证已通过', [], 1, 1);
    }

    public function rejectIdentity()
    {
        $params = $this->request->post();
        if (empty($params['id'])) {
            return $this->fail('缺少会员ID');
        }
        if (empty($params['reason'])) {
            return $this->fail('请填写驳回原因');
        }

        MemberLogic::rejectIdentity((int)$params['id']);
        return $this->success('本人认证已驳回', [], 1, 1);
    }
}
