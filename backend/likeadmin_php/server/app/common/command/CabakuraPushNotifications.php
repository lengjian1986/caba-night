<?php

declare(strict_types=1);

namespace app\common\command;

use app\adminapi\logic\cabakura\PushNotificationLogic;
use think\console\Command;
use think\console\Input;
use think\console\Output;

class CabakuraPushNotifications extends Command
{
    protected function configure()
    {
        $this->setName('cabakura_push_notifications')->setDescription('发送到期的平台推送通知');
    }

    protected function execute(Input $input, Output $output)
    {
        PushNotificationLogic::dispatchDue();
        return 0;
    }
}
