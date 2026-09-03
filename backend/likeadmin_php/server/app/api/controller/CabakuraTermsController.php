<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraTermsLogic;

class CabakuraTermsController extends BaseApiController
{
    public function lists()
    {
        return $this->success('利用規約を取得しました', ['lists' => CabakuraTermsLogic::lists()]);
    }
}
