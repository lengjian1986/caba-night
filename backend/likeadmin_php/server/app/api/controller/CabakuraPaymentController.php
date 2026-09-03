<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraPaymentLogic;

class CabakuraPaymentController extends BaseApiController
{
    public function lists()
    {
        return $this->success('支払い方法を取得しました', [
            'lists' => CabakuraPaymentLogic::lists($this->userId),
        ]);
    }

    public function create()
    {
        $result = CabakuraPaymentLogic::create($this->userId, $this->request->post());
        if (empty($result)) {
            return $this->fail('カード情報の形式が正しくありません');
        }

        return $this->success('カードを保存しました', $result);
    }
}
