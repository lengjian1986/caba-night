<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\CouponLogic;

class CouponController extends BaseAdminController
{
    public function settings()
    {
        return $this->data(CouponLogic::settings($this->request->get()));
    }

    public function shops()
    {
        return $this->data(['lists' => CouponLogic::shops()]);
    }

    public function members()
    {
        return $this->data(['lists' => CouponLogic::members($this->request->get())]);
    }

    public function distribute()
    {
        try {
            $count = CouponLogic::distribute($this->request->post());
            return $this->success($count . '名の会員にクーポンを配布しました');
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function save()
    {
        try {
            $id = CouponLogic::save($this->request->post());
            return $this->success('クーポンを保存しました', ['id' => $id], 1, 1);
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function delete()
    {
        try {
            CouponLogic::delete($this->request->post());
            return $this->success('クーポンを削除しました');
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function switchStatus()
    {
        try {
            CouponLogic::switchStatus($this->request->post());
            return $this->success('クーポンの状態を更新しました');
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function usage()
    {
        return $this->data(CouponLogic::usage($this->request->get()));
    }

    public function distribution()
    {
        return $this->data(CouponLogic::distribution($this->request->get()));
    }
}
