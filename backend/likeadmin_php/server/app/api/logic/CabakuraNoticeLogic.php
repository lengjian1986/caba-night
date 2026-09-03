<?php

declare(strict_types=1);

namespace app\api\logic;

use think\facade\Db;

class CabakuraNoticeLogic
{
    public static function lists(int $userId): array
    {
        $rows = Db::name('notice_record')->where('user_id', $userId)->order('id desc')->limit(100)->select()->toArray();
        foreach ($rows as &$row) {
            $row['create_time_text'] = (int)($row['create_time'] ?? 0) > 0 ? date('Y-m-d H:i', (int)$row['create_time']) : '';
            $row['extra'] = json_decode((string)($row['extra'] ?? ''), true) ?: [];
        }
        return ['lists' => $rows, 'unread_count' => Db::name('notice_record')->where('user_id', $userId)->where('read', 0)->count()];
    }

    public static function readAll(int $userId): void
    {
        Db::name('notice_record')->where('user_id', $userId)->where('read', 0)->update(['read' => 1, 'update_time' => time()]);
    }
}
