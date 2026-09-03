<?php

declare(strict_types=1);

namespace app\api\logic;

use app\common\enum\cabakura\SupportTicketStatusEnum;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\SupportMessage;
use app\common\model\cabakura\SupportTicket;

class CabakuraSupportLogic
{
    public static function latest(int $userId): array
    {
        if ($userId <= 0) return ['ticket' => null, 'messages' => []];
        $ticket = SupportTicket::where('member_id', $userId)->order('id desc')->find();
        if (!$ticket) return ['ticket' => null, 'messages' => []];
        $ticketData = $ticket->toArray();
        $readTime = (int)($ticketData['member_read_time'] ?? 0);
        $unreadCount = SupportMessage::where('ticket_id', (int)$ticket->id)->where('sender_type', 'admin')->where('create_time', '>', $readTime)->count();
        return ['ticket' => array_intersect_key($ticketData, array_flip(['id', 'ticket_no', 'category', 'status', 'last_message', 'create_time', 'update_time'])), 'messages' => self::messages((int)$ticket->id), 'unread_count' => $unreadCount];
    }

    public static function send(int $userId, array $params): array
    {
        if ($userId <= 0) throw new \Exception('ログインしてください');
        $content = trim((string)($params['content'] ?? ''));
        if ($content === '') throw new \Exception('お問い合わせ内容を入力してください');
        $category = trim((string)($params['category'] ?? 'その他')) ?: 'その他';
        $member = Member::where('user_id', $userId)->field('nickname')->find();
        $now = time();
        $ticket = SupportTicket::where('member_id', $userId)->whereIn('status', [SupportTicketStatusEnum::OPEN, SupportTicketStatusEnum::PENDING_OPERATOR, SupportTicketStatusEnum::PENDING_USER])->order('id desc')->find();
        if (!$ticket) {
            $ticket = SupportTicket::create(['member_id' => $userId, 'ticket_no' => 'CS' . date('YmdHis') . random_int(100, 999), 'category' => $category, 'member_name' => (string)($member?->nickname ?? '会員'), 'status' => SupportTicketStatusEnum::OPEN, 'last_message' => $content, 'create_time' => $now, 'update_time' => $now]);
        } else {
            SupportTicket::update(['id' => $ticket->id, 'category' => $category, 'status' => SupportTicketStatusEnum::OPEN, 'last_message' => $content, 'update_time' => $now]);
        }
        SupportMessage::create(['ticket_id' => (int)$ticket->id, 'sender_type' => 'member', 'sender_name' => (string)($member?->nickname ?? '会員'), 'content' => $content, 'create_time' => $now]);
        return self::latest($userId);
    }

    public static function markRead(int $userId): void
    {
        if ($userId <= 0) return;
        $ticket = SupportTicket::where('member_id', $userId)->order('id desc')->find();
        if ($ticket) SupportTicket::update(['id' => $ticket->id, 'member_read_time' => time()]);
    }

    private static function messages(int $ticketId): array
    {
        return SupportMessage::where('ticket_id', $ticketId)->field('id,sender_type,sender_name,content,create_time')->order('id asc')->select()->toArray();
    }
}
