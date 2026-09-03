<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\News;

class NewsLogic
{
    public static function lists(array $params): array
    {
        $allowSearch = ['keyword', 'is_show'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = News::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,logo_image,title,link,content,is_show,sort,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('sort desc,id desc')
            ->select();

        $rows = [];
        foreach ($lists as $item) {
            $row = $item->toArray();
            $createTime = (int)$item->getData('create_time');
            $updateTime = (int)$item->getData('update_time');
            $row['created_at'] = $createTime > 0 ? date('Y-m-d H:i', $createTime) : '';
            $row['updated_at'] = $updateTime > 0 ? date('Y-m-d H:i', $updateTime) : '';
            $rows[] = $row;
        }

        return [
            'lists' => $rows,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function save(array $params): int
    {
        $content = trim((string)($params['content'] ?? ''));
        if ($content === '') {
            throw new \Exception('本文を入力してください');
        }

        $data = [
            'logo_image' => trim((string)($params['logo_image'] ?? '')),
            'title' => trim((string)($params['title'] ?? '')),
            'link' => trim((string)($params['link'] ?? '')),
            'content' => $content,
            'is_show' => empty($params['is_show']) ? 0 : 1,
            'sort' => max((int)($params['sort'] ?? 0), 0),
            'update_time' => time(),
        ];

        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            News::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $news = News::create($data);
        return (int)$news->id;
    }

    public static function switchShow(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        News::update([
            'id' => $id,
            'is_show' => empty($params['is_show']) ? 0 : 1,
            'update_time' => time(),
        ]);

        return true;
    }
}
