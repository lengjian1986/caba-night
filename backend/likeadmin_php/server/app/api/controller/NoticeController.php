<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraNoticeLogic;

class NoticeController extends BaseApiController
{
    public function lists()
    {
        return $this->success('', CabakuraNoticeLogic::lists($this->userId));
    }

    public function readAll()
    {
        CabakuraNoticeLogic::readAll($this->userId);
        return $this->success('');
    }
}
