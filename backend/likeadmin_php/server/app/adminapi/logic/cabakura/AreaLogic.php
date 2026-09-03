<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\Area;

class AreaLogic
{
    public static function lists(array $params): array
    {
        $allowSearch = ['level', 'parent_id', 'is_show', 'is_recommended'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $keyword = trim((string)($params['keyword'] ?? ''));

        $rows = Area::withSearch($search, $params)
            ->field('id,parent_id,level,code,parent_code,name,kana,prefecture,city,sort,is_show,is_recommended,create_time,update_time')
            ->order('level asc,sort desc,code asc,id asc')
            ->select()
            ->toArray();

        foreach ($rows as &$item) {
            $item['level_text'] = self::levelText((int)$item['level']);
            $item['created_at'] = !empty($item['create_time']) ? date('Y-m-d H:i', (int)$item['create_time']) : '';
            $item['updated_at'] = !empty($item['update_time']) ? date('Y-m-d H:i', (int)$item['update_time']) : '';
        }
        unset($item);

        if ($keyword !== '') {
            $rows = self::filterRowsWithAncestors($rows, $keyword);
        }

        $lists = self::tree($rows);

        return [
            'lists' => $lists,
            'count' => count($lists),
            'page_no' => 1,
            'page_size' => max(count($lists), 1),
        ];
    }

    public static function save(array $params): int
    {
        $name = trim((string)($params['name'] ?? ''));
        $kana = trim((string)($params['kana'] ?? ''));
        $level = (int)($params['level'] ?? 2);
        $parentId = (int)($params['parent_id'] ?? 0);
        if ($name === '') {
            throw new \Exception('エリア名を入力してください');
        }
        if (!in_array($level, [1, 2, 3], true)) {
            throw new \Exception('階層を選択してください');
        }

        $current = null;
        if (!empty($params['id'])) {
            $current = Area::findOrEmpty((int)$params['id']);
            if ($current->isEmpty()) {
                throw new \Exception('エリアが存在しません');
            }
        }

        $parentCode = '';
        $prefecture = $name;
        $city = '';
        if ($level > 1) {
            if ($parentId <= 0) {
                throw new \Exception('親エリアを選択してください');
            }
            $parent = Area::findOrEmpty($parentId);
            if ($parent->isEmpty() || (int)$parent->level !== $level - 1) {
                throw new \Exception('親エリアの階層が正しくありません');
            }
            $parentCode = (string)($parent->code ?? '');
            $prefecture = (string)($parent->prefecture ?: $parent->name);
            $city = $name;
        } else {
            $parentId = 0;
        }

        $code = trim((string)($params['code'] ?? ''));
        if ($code === '' && $current !== null) {
            $code = (string)($current->code ?? '');
        }
        if ($code === '') {
            $code = 'custom-' . time() . mt_rand(1000, 9999);
        }

        $data = [
            'parent_id' => $parentId,
            'level' => $level,
            'code' => $code,
            'parent_code' => $parentCode,
            'name' => $name,
            'kana' => $kana,
            'prefecture' => $prefecture,
            'city' => $city,
            'sort' => max((int)($params['sort'] ?? 0), 0),
            'is_show' => empty($params['is_show']) ? 0 : 1,
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'update_time' => time(),
        ];

        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            Area::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $area = Area::create($data);
        return (int)$area->id;
    }

    public static function switchShow(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        Area::update([
            'id' => $id,
            'is_show' => empty($params['is_show']) ? 0 : 1,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function switchRecommended(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        Area::update([
            'id' => $id,
            'is_recommended' => empty($params['is_recommended']) ? 0 : 1,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function delete(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        $childrenCount = Area::where('parent_id', '=', $id)->count();
        if ($childrenCount > 0) {
            throw new \Exception('下位エリアがあるため削除できません');
        }

        Area::destroy($id);
        return true;
    }

    private static function levelText(int $level): string
    {
        return [
            1 => '都道府県',
            2 => '市区町村',
            3 => '区',
        ][$level] ?? '';
    }

    private static function filterRowsWithAncestors(array $rows, string $keyword): array
    {
        $map = [];
        foreach ($rows as $row) {
            $map[(int)$row['id']] = $row;
        }

        $keep = [];
        foreach ($rows as $row) {
            $haystack = implode(' ', [
                (string)$row['name'],
                (string)($row['kana'] ?? ''),
                (string)($row['prefecture'] ?? ''),
                (string)($row['city'] ?? ''),
                (string)($row['code'] ?? ''),
            ]);
            if (mb_stripos($haystack, $keyword) === false) {
                continue;
            }

            $cursor = $row;
            while (!empty($cursor)) {
                $id = (int)$cursor['id'];
                $keep[$id] = true;
                $parentId = (int)($cursor['parent_id'] ?? 0);
                $cursor = $parentId > 0 && isset($map[$parentId]) ? $map[$parentId] : null;
            }
        }

        return array_values(array_filter($rows, fn($row) => isset($keep[(int)$row['id']])));
    }

    private static function tree(array $rows): array
    {
        $map = [];
        foreach ($rows as $row) {
            $row['children'] = [];
            $map[(int)$row['id']] = $row;
        }

        $tree = [];
        foreach ($map as $id => &$row) {
            $parentId = (int)($row['parent_id'] ?? 0);
            if ($parentId > 0 && isset($map[$parentId])) {
                $map[$parentId]['children'][] = &$row;
                continue;
            }
            $tree[] = &$row;
        }
        unset($row);

        return $tree;
    }
}
