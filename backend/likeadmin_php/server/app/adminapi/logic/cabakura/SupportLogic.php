<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\enum\cabakura\SupportTicketStatusEnum;
use app\common\model\cabakura\SupportMessage;
use app\common\model\cabakura\SupportTicket;

class SupportLogic
{
    public static function tickets(array $params): array
    {
        $allowSearch = ['keyword', 'status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);
        $query = SupportTicket::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,ticket_no,category,member_name,order_no,shop_name,status,last_message,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['status_text'] = SupportTicketStatusEnum::label($item['status']);
            $item['updated_at'] = self::formatTime($item['update_time']);
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function updateStatus(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        $status = (string)($params['status'] ?? '');
        $allowedStatuses = [
            SupportTicketStatusEnum::OPEN,
            SupportTicketStatusEnum::PENDING_OPERATOR,
            SupportTicketStatusEnum::RESOLVED,
        ];

        if ($id <= 0) {
            throw new \Exception('チケットを選択してください');
        }

        if (!in_array($status, $allowedStatuses, true)) {
            throw new \Exception('ステータスを選択してください');
        }

        SupportTicket::update([
            'id' => $id,
            'status' => $status,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function messages(array $params): array
    {
        $ticketId = (int)($params['ticket_id'] ?? 0);
        if ($ticketId <= 0) {
            return [];
        }

        $messages = SupportMessage::where(['ticket_id' => $ticketId])
            ->field('id,ticket_id,sender_type,sender_name,content,create_time')
            ->order('id asc')
            ->select()
            ->toArray();

        foreach ($messages as &$message) {
            $message['created_at'] = self::formatTime($message['create_time'], '');
        }

        return $messages;
    }

    public static function reply(array $params): bool
    {
        $ticketId = (int)($params['ticket_id'] ?? 0);
        $content = trim((string)($params['content'] ?? ''));
        $status = (string)($params['status'] ?? SupportTicketStatusEnum::PENDING_USER);
        $allowedStatuses = [
            SupportTicketStatusEnum::OPEN,
            SupportTicketStatusEnum::PENDING_OPERATOR,
            SupportTicketStatusEnum::PENDING_USER,
            SupportTicketStatusEnum::RESOLVED,
        ];

        if ($ticketId <= 0) {
            throw new \Exception('チケットを選択してください');
        }

        if ($content === '') {
            throw new \Exception('返信内容を入力してください');
        }

        if (!in_array($status, $allowedStatuses, true)) {
            throw new \Exception('ステータスを選択してください');
        }

        SupportMessage::create([
            'ticket_id' => $ticketId,
            'sender_type' => 'admin',
            'sender_name' => '管理者',
            'content' => $content,
            'create_time' => time(),
        ]);

        SupportTicket::update([
            'id' => $ticketId,
            'status' => $status,
            'last_message' => $content,
            'update_time' => time(),
        ]);

        return true;
    }

    private static function formatTime($value, string $empty = '-'): string
    {
        $timezone = new \DateTimeZone('Asia/Tokyo');
        if (is_numeric($value) && (int)$value > 0) {
            return (new \DateTimeImmutable('@' . (int)$value))->setTimezone($timezone)->format('Y-m-d H:i');
        }
        if (trim((string)$value) !== '') {
            try {
                return (new \DateTimeImmutable((string)$value, $timezone))->setTimezone($timezone)->format('Y-m-d H:i');
            } catch (\Throwable $e) {
                return $empty;
            }
        }
        return $empty;
    }
}
