<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraSupportLogic;

class CabakuraSupportController extends BaseApiController
{
    public function latest()
    {
        return $this->success('お問い合わせ履歴を取得しました', CabakuraSupportLogic::latest($this->userId));
    }

    public function send()
    {
        try {
            return $this->success('お問い合わせを送信しました', CabakuraSupportLogic::send($this->userId, $this->request->post()));
        } catch (\Throwable $e) {
            return $this->fail($e->getMessage());
        }
    }

    public function read()
    {
        CabakuraSupportLogic::markRead($this->userId);
        return $this->success('既読にしました');
    }
}
