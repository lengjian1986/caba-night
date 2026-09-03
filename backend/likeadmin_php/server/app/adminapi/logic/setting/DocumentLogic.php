<?php

declare(strict_types=1);

namespace app\adminapi\logic\setting;

use app\common\logic\BaseLogic;
use app\common\service\ConfigService;

class DocumentLogic extends BaseLogic
{
    public static function getConfig(): array
    {
        $documents = ConfigService::get('document_setting', 'documents', []);
        if (!is_array($documents)) {
            $documents = [];
        }

        return [
            'documents' => array_values(array_map(function ($item) {
                return [
                    'title' => (string)($item['title'] ?? ''),
                    'usage_target' => (string)($item['usage_target'] ?? ($item['description'] ?? '')),
                    'content' => (string)($item['content'] ?? ''),
                    'status' => empty($item['status'])
                        ? (empty($item['is_show']) ? 'disabled' : 'enabled')
                        : (string)$item['status'],
                ];
            }, $documents)),
        ];
    }

    public static function setConfig(array $params): void
    {
        $documents = $params['documents'] ?? [];
        if (!is_array($documents)) {
            $documents = [];
        }

        $normalized = [];
        foreach ($documents as $item) {
            if (!is_array($item)) {
                continue;
            }

            $title = trim((string)($item['title'] ?? ''));
            $usageTarget = trim((string)($item['usage_target'] ?? ''));
            $content = trim((string)($item['content'] ?? ''));
            if ($title === '' && $usageTarget === '' && $content === '') {
                continue;
            }

            $normalized[] = [
                'title' => $title,
                'usage_target' => $usageTarget,
                'content' => $content,
                'status' => in_array(($item['status'] ?? ''), ['enabled', 'disabled'], true)
                    ? (string)$item['status']
                    : 'enabled',
            ];
        }

        ConfigService::set('document_setting', 'documents', $normalized);
    }
}
