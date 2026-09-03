<?php

declare(strict_types=1);

namespace app\api\controller;

use app\api\logic\CabakuraHomeLogic;
use think\response\Json;

class CabakuraHomeController extends BaseApiController
{
    public array $notNeedLogin = ['index', 'detail', 'castSchedule', 'location'];

    public function index(): Json
    {
        return $this->data(CabakuraHomeLogic::index($this->request->get()));
    }

    public function detail(): Json
    {
        return $this->data(CabakuraHomeLogic::detail($this->request->get()));
    }

    public function castSchedule(): Json
    {
        return $this->data(CabakuraHomeLogic::castSchedule($this->request->get()));
    }

    public function location(): Json
    {
        return $this->data(CabakuraHomeLogic::resolveLocation($this->request->get()));
    }
}
