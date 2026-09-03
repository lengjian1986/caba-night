<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\dict\DictData;
use app\common\model\dict\DictType;

class AnswerSettingLogic
{
    private const GROUPS = [
        'cast' => [
            'label' => 'Cast信息',
            'fields' => [
                ['name' => '喜欢类型', 'type' => 'cbk_cast_preferred_male_type', 'remark' => 'Cast喜欢类型下拉选项'],
                ['name' => '抽烟喝酒', 'type' => 'cbk_cast_smoking_drinking', 'remark' => 'Cast抽烟喝酒合并下拉选项'],
            ],
        ],
        'shop' => [
            'label' => 'Shop信息',
            'fields' => [
                ['name' => 'セットプランタグ', 'type' => 'cbk_shop_plan_tag', 'remark' => 'セットプラン作成時のタグ選択肢'],
            ],
        ],
    ];

    private const REMOVED_TYPES = [
        'cbk_cast_smoking_status',
        'cbk_cast_drinking_status',
    ];

    public static function fields(): array
    {
        self::deleteRemovedTypes();

        $types = [];
        foreach (self::GROUPS as $group) {
            foreach ($group['fields'] as $field) {
                $types[] = $field['type'];
                self::ensureDictType($field);
            }
        }

        $typeRows = DictType::whereIn('type', $types)
            ->column('id,name,type,status,remark', 'type');
        $dataRows = DictData::whereIn('type_value', $types)
            ->order(['sort' => 'desc', 'id' => 'asc'])
            ->select()
            ->toArray();

        $optionMap = [];
        foreach ($dataRows as $row) {
            $optionMap[$row['type_value']][] = $row;
        }

        $groups = [];
        foreach (self::GROUPS as $key => $group) {
            $fields = [];
            foreach ($group['fields'] as $field) {
                $type = $typeRows[$field['type']] ?? [];
                $fields[] = [
                    'name' => $field['name'],
                    'type' => $field['type'],
                    'remark' => $field['remark'],
                    'type_id' => (int)($type['id'] ?? 0),
                    'status' => (int)($type['status'] ?? 1),
                    'options' => $optionMap[$field['type']] ?? [],
                ];
            }

            $groups[] = [
                'key' => $key,
                'label' => $group['label'],
                'fields' => $fields,
            ];
        }

        return $groups;
    }

    public static function saveOption(array $params): int
    {
        $type = trim((string)($params['type'] ?? ''));
        $name = trim((string)($params['name'] ?? ''));
        $value = trim((string)($params['value'] ?? ''));
        if ($type === '' || $name === '' || $value === '') {
            throw new \Exception('请填写选项名称和选项值');
        }

        $field = self::findField($type);
        $dictType = self::ensureDictType($field);
        $data = [
            'name' => $name,
            'value' => $value,
            'sort' => max((int)($params['sort'] ?? 0), 0),
            'status' => empty($params['status']) ? 0 : 1,
            'remark' => trim((string)($params['remark'] ?? '')),
            'type_value' => $type,
        ];

        if (!empty($params['id'])) {
            DictData::where(['id' => (int)$params['id']])->update($data);
            return (int)$params['id'];
        }

        $data['type_id'] = (int)$dictType->id;
        $option = DictData::create($data);
        return (int)$option->id;
    }

    public static function deleteOption(array $params): void
    {
        $id = $params['id'] ?? 0;
        if (empty($id)) {
            throw new \Exception('缺少选项ID');
        }

        DictData::destroy($id);
    }

    private static function ensureDictType(array $field)
    {
        $dictType = DictType::where(['type' => $field['type']])->findOrEmpty();
        if (!$dictType->isEmpty()) {
            return $dictType;
        }

        return DictType::create([
            'name' => $field['name'],
            'type' => $field['type'],
            'status' => 1,
            'remark' => $field['remark'],
        ]);
    }

    private static function findField(string $type): array
    {
        foreach (self::GROUPS as $group) {
            foreach ($group['fields'] as $field) {
                if ($field['type'] === $type) {
                    return $field;
                }
            }
        }

        throw new \Exception('不支持的选项字段');
    }

    private static function deleteRemovedTypes(): void
    {
        $typeIds = DictType::whereIn('type', self::REMOVED_TYPES)->column('id');
        if ($typeIds) {
            DictData::whereIn('type_id', $typeIds)->delete();
            DictData::whereIn('type_value', self::REMOVED_TYPES)->delete();
            DictType::destroy($typeIds);
        }
    }
}
