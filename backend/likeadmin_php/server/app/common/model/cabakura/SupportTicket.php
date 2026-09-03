<?php

declare(strict_types=1);

namespace app\common\model\cabakura;

use app\common\model\BaseModel;
use think\model\concern\SoftDelete;

class SupportTicket extends BaseModel
{
    use SoftDelete;

    protected $name = 'cbk_support_ticket';
    protected $deleteTime = 'delete_time';

    public function searchKeywordAttr($query, $value, $data)
    {
        if ($value) {
            $query->where('ticket_no|order_no|member_name|shop_name', 'like', '%' . $value . '%');
        }
    }

    public function searchStatusAttr($query, $value, $data)
    {
        if ($value) {
            $groups = [
                'in_progress' => ['pending_operator', 'pending_user'],
                'done' => ['resolved', 'closed'],
            ];

            if (isset($groups[$value])) {
                $query->whereIn('status', $groups[$value]);
                return;
            }

            $query->where('status', '=', $value);
        }
    }

    public function getUpdatedAtAttr($value, $data): string
    {
        $time = $data['update_time'] ?? 0;
        return $time ? date('Y-m-d H:i', (int)$time) : '';
    }
}
