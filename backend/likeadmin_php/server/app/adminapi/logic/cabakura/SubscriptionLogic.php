<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\model\cabakura\Subscription;
use app\common\model\cabakura\SubscriptionPlan;
use app\common\model\cabakura\SubscriptionRecord;

class SubscriptionLogic
{
    public static function users(array $params): array
    {
        $allowSearch = ['keyword', 'status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = Subscription::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,member_id,member_no,nickname,mobile,plan_id,plan_name,start_time,end_time,status,auto_renew,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['mobile_masked'] = self::maskMobile((string)$item['mobile']);
            $item['status_text'] = self::subscriptionStatusText((string)$item['status']);
            $item['start_time_text'] = self::formatTime((int)$item['start_time']);
            $item['end_time_text'] = self::formatTime((int)$item['end_time']);
        }

        return self::page($lists, $count, $pageNo, $pageSize);
    }

    public static function records(array $params): array
    {
        $allowSearch = ['keyword', 'pay_status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = SubscriptionRecord::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,subscription_id,member_id,member_no,nickname,plan_id,plan_name,amount,action,pay_status,transaction_no,create_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['action_text'] = self::recordActionText((string)$item['action']);
            $item['pay_status_text'] = self::payStatusText((string)$item['pay_status']);
            $item['create_time_text'] = self::formatTime((int)$item['create_time']);
        }

        return self::page($lists, $count, $pageNo, $pageSize);
    }

    public static function plans(array $params): array
    {
        $allowSearch = ['keyword', 'is_enabled'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = SubscriptionPlan::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,name,price,duration_days,description,benefits,is_enabled,sort,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('sort desc,id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['created_at'] = self::formatTime((int)$item['create_time']);
            $item['updated_at'] = self::formatTime((int)$item['update_time']);
        }

        return self::page($lists, $count, $pageNo, $pageSize);
    }

    public static function savePlan(array $params): int
    {
        $name = trim((string)($params['name'] ?? ''));
        if ($name === '') {
            throw new \Exception('Plan名を入力してください');
        }

        $data = [
            'name' => $name,
            'price' => max((int)($params['price'] ?? 0), 0),
            'duration_days' => max((int)($params['duration_days'] ?? 30), 1),
            'description' => trim((string)($params['description'] ?? '')),
            'benefits' => json_encode(self::normalizeStringList($params['benefits'] ?? []), JSON_UNESCAPED_UNICODE),
            'is_enabled' => empty($params['is_enabled']) ? 0 : 1,
            'sort' => max((int)($params['sort'] ?? 0), 0),
            'update_time' => time(),
        ];

        if (!empty($params['id'])) {
            $data['id'] = (int)$params['id'];
            SubscriptionPlan::update($data);
            return (int)$params['id'];
        }

        $data['create_time'] = time();
        $plan = SubscriptionPlan::create($data);
        return (int)$plan->id;
    }

    public static function switchPlan(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        SubscriptionPlan::update([
            'id' => $id,
            'is_enabled' => empty($params['is_enabled']) ? 0 : 1,
            'update_time' => time(),
        ]);
        return true;
    }

    private static function page(array $lists, int $count, int $pageNo, int $pageSize): array
    {
        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    private static function normalizeStringList($items): array
    {
        if (!is_array($items)) {
            return [];
        }

        $normalized = [];
        foreach ($items as $item) {
            $value = trim((string)$item);
            if ($value !== '') {
                $normalized[] = $value;
            }
        }

        return $normalized;
    }

    private static function formatTime(int $time): string
    {
        return $time > 0 ? date('Y-m-d H:i', $time) : '';
    }

    private static function maskMobile(string $mobile): string
    {
        if (strlen($mobile) < 7) {
            return $mobile;
        }

        return substr($mobile, 0, 3) . '****' . substr($mobile, -4);
    }

    private static function subscriptionStatusText(string $status): string
    {
        return [
            'active' => '契約中',
            'expired' => '期限切れ',
            'cancelled' => '解約済み',
        ][$status] ?? $status;
    }

    private static function recordActionText(string $action): string
    {
        return [
            'subscribe' => '新規契約',
            'renew' => '更新',
            'cancel' => '解約',
            'refund' => '返金',
        ][$action] ?? $action;
    }

    private static function payStatusText(string $status): string
    {
        return [
            'paid' => '支払済み',
            'pending' => '支払待ち',
            'failed' => '失敗',
            'refunded' => '返金済み',
        ][$status] ?? $status;
    }
}
