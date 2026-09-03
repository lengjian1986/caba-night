<?php

declare(strict_types=1);

namespace app\adminapi\controller\setting;

use app\adminapi\controller\BaseAdminController;
use app\adminapi\logic\setting\DocumentLogic;

class DocumentController extends BaseAdminController
{
    public function getConfig()
    {
        return $this->data(DocumentLogic::getConfig());
    }

    public function setConfig()
    {
        DocumentLogic::setConfig($this->request->post());
        return $this->success('保存しました', [], 1, 1);
    }
}
