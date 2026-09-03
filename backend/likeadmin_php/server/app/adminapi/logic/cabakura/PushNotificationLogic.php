<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use think\facade\Db;

class PushNotificationLogic
{
    public static function lists(array $params): array
    {
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);
        $query = Db::name('cbk_push_notification');
        if (!empty($params['keyword'])) {
            $keyword = '%' . trim((string)$params['keyword']) . '%';
            $query->whereLike('title|content', $keyword);
        }
        $count = (clone $query)->count();
        $items = $query->order('id desc')->limit(($pageNo - 1) * $pageSize, $pageSize)->select()->toArray();
        foreach ($items as &$item) {
            $item['scheduled_at_text'] = (int)$item['scheduled_at'] > 0 ? date('Y-m-d H:i', (int)$item['scheduled_at']) : '-';
            $item['sent_at_text'] = (int)$item['sent_at'] > 0 ? date('Y-m-d H:i', (int)$item['sent_at']) : '-';
        }
        return ['lists' => $items, 'count' => $count, 'page_no' => $pageNo, 'page_size' => $pageSize];
    }

    public static function save(array $params): int
    {
        $title = trim((string)($params['title'] ?? ''));
        $content = trim((string)($params['content'] ?? ''));
        $mode = ($params['mode'] ?? 'immediate') === 'scheduled' ? 'scheduled' : 'immediate';
        if ($title === '' || $content === '') throw new \Exception('タイトルと内容を入力してください');
        $scheduledAt = $mode === 'scheduled' ? strtotime((string)($params['scheduled_at'] ?? '')) : 0;
        if ($mode === 'scheduled' && $scheduledAt <= time()) throw new \Exception('未来の配信日時を指定してください');
        $data = ['title' => $title, 'content' => $content, 'link' => trim((string)($params['link'] ?? '')), 'mode' => $mode, 'scheduled_at' => $scheduledAt, 'status' => $mode === 'immediate' ? 'sent' : 'pending', 'update_time' => time()];
        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            Db::name('cbk_push_notification')->update($data);
            return (int)$params['id'];
        }
        $data['create_time'] = time();
        $id = (int)Db::name('cbk_push_notification')->insertGetId($data);
        if ($mode === 'immediate') self::dispatch($id);
        return $id;
    }

    public static function dispatchDue(): void
    {
        $ids = Db::name('cbk_push_notification')->where('status', 'pending')->where('scheduled_at', '<=', time())->column('id');
        foreach ($ids as $id) self::dispatch((int)$id);
    }

    private static function dispatch(int $id): void
    {
        Db::transaction(function () use ($id) {
            $push = Db::name('cbk_push_notification')->where('id', $id)->where('status', 'in', ['pending', 'sent'])->find();
            if (!$push || ($push['status'] === 'sent' && $push['mode'] !== 'immediate')) return;
            $users = Db::name('user')->where('delete_time', 0)->where('is_disable', 0)->column('id');
            $now = time();
            foreach ($users as $userId) {
                Db::name('notice_record')->insert([
                    'user_id' => $userId, 'title' => $push['title'], 'content' => $push['content'],
                    'scene_id' => 0, 'read' => 0, 'recipient' => 1, 'send_type' => 1,
                    'notice_type' => 1, 'extra' => json_encode(['link' => $push['link']], JSON_UNESCAPED_UNICODE),
                    'create_time' => $now, 'update_time' => $now,
                ]);
            }
            Db::name('cbk_push_notification')->where('id', $id)->update(['status' => 'sent', 'sent_at' => $now, 'update_time' => $now]);
        });
    }
}
