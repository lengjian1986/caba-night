<?php

declare(strict_types=1);

namespace app\adminapi\logic\cabakura;

use app\common\enum\cabakura\IdentityStatusEnum;
use app\common\enum\cabakura\MemberStatusEnum;
use app\common\enum\YesNoEnum;
use app\common\model\cabakura\Member;
use app\common\model\cabakura\MemberDeleteRecord;
use app\common\model\user\User;

class MemberLogic
{
    private const LEVEL_GENERAL = '一般会員';
    private const LEVEL_PREMIUM = 'プレミアム会員';
    private const LEVEL_SUPER = 'supermember';

    public static function lists(array $params): array
    {
        $allowSearch = ['keyword', 'identity_status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = Member::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,user_id,avatar,member_no,nickname,real_name,mobile,email,nationality,postal_code,address,building_name,level_name,identity_status,identity_image,status,wallet_balance,order_count,favorite_count,review_count,create_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->append(['mobile_masked'])
            ->toArray();

        foreach ($lists as &$item) {
            $item['identity_status_text'] = IdentityStatusEnum::label($item['identity_status']);
            $item['status_text'] = MemberStatusEnum::label($item['status']);
            $item['create_time_text'] = is_numeric($item['create_time'])
                ? date('Y-m-d H:i', (int)$item['create_time'])
                : (string)$item['create_time'];
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function deleteRecords(array $params): array
    {
        $allowSearch = ['keyword', 'status'];
        $search = array_intersect(array_keys($params), $allowSearch);
        $pageNo = max((int)($params['page_no'] ?? 1), 1);
        $pageSize = max((int)($params['page_size'] ?? 15), 1);

        $query = MemberDeleteRecord::withSearch($search, $params);
        $count = (clone $query)->count();
        $lists = $query
            ->field('id,member_id,member_no,nickname,mobile,reason,status,requested_time,processed_time,operator,remark,create_time,update_time')
            ->limit(($pageNo - 1) * $pageSize, $pageSize)
            ->order('id desc')
            ->select()
            ->toArray();

        foreach ($lists as &$item) {
            $item['mobile_masked'] = self::maskMobile((string)$item['mobile']);
            $item['status_text'] = self::deleteRecordStatusText((string)$item['status']);
            $item['requested_time_text'] = !empty($item['requested_time'])
                ? date('Y-m-d H:i', (int)$item['requested_time'])
                : '';
            $item['processed_time_text'] = !empty($item['processed_time'])
                ? date('Y-m-d H:i', (int)$item['processed_time'])
                : '';
        }

        return [
            'lists' => $lists,
            'count' => $count,
            'page_no' => $pageNo,
            'page_size' => $pageSize,
        ];
    }

    public static function detail(int $id): array
    {
        $member = Member::findOrEmpty($id);
        if ($member->isEmpty()) {
            return [];
        }

        $data = $member
            ->visible([
                'id',
                'user_id',
                'avatar',
                'member_no',
                'nickname',
                'real_name',
                'mobile',
                'email',
                'nationality',
                'postal_code',
                'address',
                'building_name',
                'level_name',
                'identity_status',
                'identity_image',
                'status',
                'wallet_balance',
                'order_count',
                'favorite_count',
                'review_count',
                'create_time',
                'update_time',
            ])
            ->append(['mobile_masked'])
            ->toArray();

        $data['identity_status_text'] = IdentityStatusEnum::label($data['identity_status']);
        $data['status_text'] = MemberStatusEnum::label($data['status']);
        $data['create_time_text'] = is_numeric($data['create_time'])
            ? date('Y-m-d H:i', (int)$data['create_time'])
            : (string)$data['create_time'];
        $data['update_time_text'] = is_numeric($data['update_time'])
            ? date('Y-m-d H:i', (int)$data['update_time'])
            : (string)$data['update_time'];

        return $data;
    }

    public static function updateProfile(array $params): bool
    {
        $id = (int)($params['id'] ?? 0);
        if ($id <= 0) {
            return false;
        }

        $levelName = trim((string)($params['level_name'] ?? self::LEVEL_GENERAL));
        if (!in_array($levelName, [self::LEVEL_GENERAL, self::LEVEL_PREMIUM, self::LEVEL_SUPER], true)) {
            $levelName = self::LEVEL_GENERAL;
        }

        $member = Member::findOrEmpty($id);
        $status = trim((string)($params['status'] ?? MemberStatusEnum::NORMAL));
        if (!in_array($status, [MemberStatusEnum::NORMAL, MemberStatusEnum::DISABLED], true)) {
            $status = MemberStatusEnum::NORMAL;
        }
        $identityStatus = trim((string)($params['identity_status'] ?? IdentityStatusEnum::REJECTED));
        if (!in_array($identityStatus, [IdentityStatusEnum::APPROVED, IdentityStatusEnum::REJECTED], true)) {
            $identityStatus = IdentityStatusEnum::REJECTED;
        }

        Member::update([
            'id' => $id,
            'avatar' => trim((string)($params['avatar'] ?? '')),
            'nickname' => trim((string)($params['nickname'] ?? '')),
            'real_name' => trim((string)($params['real_name'] ?? '')),
            'mobile' => trim((string)($params['mobile'] ?? '')),
            'email' => trim((string)($params['email'] ?? '')),
            'nationality' => trim((string)($params['nationality'] ?? '日本')),
            'postal_code' => trim((string)($params['postal_code'] ?? '')),
            'address' => trim((string)($params['address'] ?? '')),
            'building_name' => trim((string)($params['building_name'] ?? '')),
            'level_name' => $levelName,
            'wallet_balance' => max(0, (int)($params['wallet_balance'] ?? 0)),
            'identity_status' => $identityStatus,
            'identity_image' => trim((string)($params['identity_image'] ?? '')),
            'status' => $status,
            'update_time' => time(),
        ]);

        if (!$member->isEmpty() && (int)$member['user_id'] > 0) {
            User::update([
                'id' => (int)$member['user_id'],
                'avatar' => trim((string)($params['avatar'] ?? '')),
                'nickname' => trim((string)($params['nickname'] ?? '')),
                'real_name' => trim((string)($params['real_name'] ?? '')),
                'mobile' => trim((string)($params['mobile'] ?? '')),
                'is_disable' => $status === MemberStatusEnum::DISABLED
                    ? YesNoEnum::YES
                    : YesNoEnum::NO,
                'update_time' => time(),
            ]);
        }

        return true;
    }

    public static function approveIdentity(int $id): bool
    {
        if ($id <= 0) {
            return false;
        }

        Member::update([
            'id' => $id,
            'identity_status' => IdentityStatusEnum::APPROVED,
            'update_time' => time(),
        ]);

        return true;
    }

    public static function rejectIdentity(int $id): bool
    {
        if ($id <= 0) {
            return false;
        }

        Member::update([
            'id' => $id,
            'identity_status' => IdentityStatusEnum::REJECTED,
            'update_time' => time(),
        ]);

        return true;
    }

    private static function maskMobile(string $mobile): string
    {
        if (strlen($mobile) < 7) {
            return $mobile;
        }

        return substr($mobile, 0, 3) . '****' . substr($mobile, -4);
    }

    private static function deleteRecordStatusText(string $status): string
    {
        return [
            'requested' => '申請中',
            'processed' => '消去済み',
            'cancelled' => 'キャンセル',
        ][$status] ?? $status;
    }
}
