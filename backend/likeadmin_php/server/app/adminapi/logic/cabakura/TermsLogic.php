<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\Terms;

class TermsLogic
{
    public static function lists(array $params): array
    {
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);
        $query = Terms::where(function ($query) use ($params) {
            $keyword = trim((string)($params['keyword'] ?? ''));
            if ($keyword !== '') $query->whereLike('name|title|content', '%' . $keyword . '%');
            if (($params['is_show'] ?? '') !== '') $query->where('is_show', (int)$params['is_show']);
        });
        $count = (clone $query)->count();
        $lists = $query->field('id,name,title,content,applies_to,is_show,sort,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)->order('sort desc,id desc')->select()->toArray();
        foreach ($lists as &$item) {
            $item['updated_at'] = self::formatTime($item['update_time'], $item['create_time']);
        }
        return ['lists' => $lists, 'count' => $count, 'page_no' => $pageNo, 'page_size' => $pageSize];
    }

    public static function save(array $params): int
    {
        $name = trim((string)($params['name'] ?? ''));
        $title = trim((string)($params['title'] ?? ''));
        $content = trim((string)($params['content'] ?? ''));
        if ($name === '' || $title === '' || $content === '') throw new \Exception('条款名称、主题和内容均为必填项');
        $data = [
            'name' => $name, 'title' => $title, 'content' => $content,
            'applies_to' => trim((string)($params['applies_to'] ?? 'all')) ?: 'all',
            'is_show' => empty($params['is_show']) ? 0 : 1,
            'sort' => max((int)($params['sort'] ?? 0), 0), 'update_time' => time(),
        ];
        if (!empty($params['id'])) { $data['id'] = (int)$params['id']; Terms::update($data); return (int)$params['id']; }
        $data['create_time'] = time();
        return (int)Terms::create($data)->id;
    }

    public static function switchShow(array $params): void
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) throw new \Exception('条款が見つかりません');
        Terms::update(['id' => $id, 'is_show' => empty($params['is_show']) ? 0 : 1, 'update_time' => time()]);
    }

    private static function formatTime($value, $fallback = 0): string
    {
        $timezone = new \DateTimeZone('Asia/Tokyo');
        if (is_numeric($value)) {
            $time = (int)$value;
            if ($time > 0) {
                return (new \DateTimeImmutable('@' . $time))->setTimezone($timezone)->format('Y-m-d H:i');
            }
        } elseif (trim((string)$value) !== '') {
            try {
                return (new \DateTimeImmutable((string)$value, $timezone))->setTimezone($timezone)->format('Y-m-d H:i');
            } catch (\Throwable $e) {
                // Fall through to the creation time for malformed legacy values.
            }
        }
        if (is_numeric($fallback) && (int)$fallback > 0) {
            return (new \DateTimeImmutable('@' . (int)$fallback))->setTimezone($timezone)->format('Y-m-d H:i');
        }
        return '-';
    }
}
