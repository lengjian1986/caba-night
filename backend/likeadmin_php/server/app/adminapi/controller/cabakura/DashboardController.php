<?php

declare(strict_types=1);

namespace app\adminapi\controller\cabakura;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\cabakura\DashboardLogic;

class DashboardController extends BaseAdminController
{
    public function summary()
    {
        return $this->data(DashboardLogic::summary());
    }
}
