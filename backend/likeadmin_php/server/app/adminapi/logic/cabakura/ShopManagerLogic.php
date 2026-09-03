<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\ShopManager;
use think\facade\Config;

class ShopManagerLogic
{
    public static function lists(array $params): array
    {
        $allowSearch = ['keyword'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = ShopManager::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,name,mobile,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['create_time_text'] = !empty($item['create_time'])
                ? date('Y-m-d H:i', (int)$item['create_time'])
                : '';
            $item['update_time_text'] = !empty($item['update_time'])
                ? date('Y-m-d H:i', (int)$item['update_time'])
                : '';
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function save(array $params): int
    {
        $id = (int)($params['id'] ?? 0);
        $data = [
            'name' => trim((string)($params['name'] ?? '')),
            'mobile' => trim((string)($params['mobile'] ?? '')),
            'update_time' => time(),
        ];

        if (!empty($params['password'])) {
            $passwordSalt = Config::get('project.unique_identification');
            $data['password'] = create_password((string)$params['password'], $passwordSalt);
        }

        if ($id > 0) {
            $data['id'] = $id;
            ShopManager::update($data);
            return $id;
        }

        $data['create_time'] = time();
        $manager = ShopManager::create($data);
        return (int)$manager->id;
    }

    public static function delete(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id > 0) {
            ShopManager::destroy($id);
        }

        return true;
    }
}
