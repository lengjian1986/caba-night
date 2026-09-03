<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\ShopPortalLogic;

class ShopPortalController extends BaseAdminController
{
    public array $notNeedLogin = [
        'login',
        'selectShop',
        'dashboard',
        'saveProfile',
        'savePlan',
        'saveBusinessStatus',
        'unboundCasts',
        'bindCast',
        'saveCastAttendance',
        'answerFields',
        'confirmOrder',
        'rejectOrder',
        'cancelOrder',
    ];

    public function login()
    {
        $params = $this->request->post();
        if (empty($params['mobile']) || empty($params['password'])) {
            return $this->fail('电话号和密码不能为空');
        }

        $data = ShopPortalLogic::login($params);
        if (empty($data)) {
            return $this->fail('电话号或密码错误');
        }

        return $this->data($data);
    }

    public function selectShop()
    {
        $data = ShopPortalLogic::selectShop($this->request->post());
        if (empty($data)) {
            return $this->fail('没有该店铺的管理权限');
        }

        return $this->data($data);
    }

    public function dashboard()
    {
        $data = ShopPortalLogic::dashboard((string)$this->request->header('shop-token'));
        if (empty($data)) {
            return $this->fail('店铺登录已过期，请重新登录');
        }

        return $this->data($data);
    }

    public function savePlan()
    {
        $result = ShopPortalLogic::savePlan(
            (string)$this->request->header('shop-token'),
            $this->request->post()
        );
        if (!$result) {
            return $this->fail('店铺登录已过期，请重新登录');
        }

        return $this->success('プランを保存しました');
    }

    public function saveProfile()
    {
        $result = ShopPortalLogic::saveProfile(
            (string)$this->request->header('shop-token'),
            $this->request->post()
        );
        if (empty($result)) {
            return $this->fail('店舗資料を保存できませんでした');
        }

        return $this->success('店舗資料を保存しました', $result, 1, 1);
    }

    public function saveBusinessStatus()
    {
        $result = ShopPortalLogic::saveBusinessStatus(
            (string)$this->request->header('shop-token'),
            $this->request->post()
        );
        if (empty($result)) {
            return $this->fail('営業状態を更新できませんでした');
        }

        return $this->success('営業状態を更新しました', $result, 1, 1);
    }

    public function unboundCasts()
    {
        $data = ShopPortalLogic::unboundCasts((string)$this->request->header('shop-token'));
        if ($data === null) {
            return $this->fail('店铺登录已过期，请重新登录');
        }

        return $this->data($data);
    }

    public function bindCast()
    {
        $result = ShopPortalLogic::bindCast(
            (string)$this->request->header('shop-token'),
            $this->request->post()
        );
        if (!$result) {
            return $this->fail('Castを追加できませんでした');
        }

        return $this->success('キャストを追加しました');
    }

    public function saveCastAttendance()
    {
        $result = ShopPortalLogic::saveCastAttendance(
            (string)$this->request->header('shop-token'),
            $this->request->post()
        );
        if (!$result) {
            return $this->fail('出勤状態を保存できませんでした');
        }

        return $this->success('出勤状態を保存しました');
    }

    public function answerFields()
    {
        $data = ShopPortalLogic::answerFields((string)$this->request->header('shop-token'));
        if ($data === null) {
            return $this->fail('店铺登录已过期，请重新登录');
        }

        return $this->data($data);
    }

    public function confirmOrder()
    {
        return $this->orderStatus('confirmed', '予約を確定しました');
    }

    public function rejectOrder()
    {
        return $this->orderStatus('cancelled', '予約を拒否しました');
    }

    public function cancelOrder()
    {
        return $this->orderStatus('cancelled', '予約をキャンセルしました');
    }

    private function orderStatus(string $status, string $message)
    {
        $result = ShopPortalLogic::updateOrderStatus(
            (string)$this->request->header('shop-token'),
            $this->request->post(),
            $status
        );
        if (!$result) {
            return $this->fail('注文を更新できませんでした');
        }

        return $this->success($message);
    }
}
