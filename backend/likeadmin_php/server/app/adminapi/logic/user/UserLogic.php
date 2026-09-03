<?php
// +----------------------------------------------------------------------
// | likeadmin快速开发前后端分离管理后台（PHP版）
// +----------------------------------------------------------------------
// | 欢迎阅读学习系统程序代码，建议反馈是我们前进的动力
// | 开源版本可自由商用，可去除界面版权logo
// | gitee下载：https://gitee.com/likeshop_gitee/likeadmin
// | github下载：https://github.com/likeshop-github/likeadmin
// | 访问官网：https://www.likeadmin.cn
// | likeadmin团队 版权所有 拥有最终解释权
// +----------------------------------------------------------------------
// | author: likeadminTeam
// +----------------------------------------------------------------------
namespace app\adminapi\logic\user;

use app\common\enum\user\AccountLogEnum;
use app\common\enum\user\UserTerminalEnum;
use app\common\logic\AccountLogLogic;
use app\common\logic\BaseLogic;
use app\common\model\user\User;
use app\common\model\cabakura\Member;
use app\common\service\FileService;
use think\facade\Db;

/**
 * 用户逻辑层
 * Class UserLogic
 * @package app\adminapi\logic\user
 */
class UserLogic extends BaseLogic
{

    /**
     * @notes 用户详情
     * @param int $userId
     * @return array
     * @author 段誉
     * @date 2022/9/22 16:32
     */
    public static function detail(int $userId): array
    {
        $field = [
            'id', 'sn', 'account', 'nickname', 'avatar', 'real_name',
            'sex', 'mobile', 'create_time', 'login_time', 'channel',
            'user_money',
        ];

        $user = User::where(['id' => $userId])->field($field)
            ->findOrEmpty();

        $member = Member::where('user_id', $userId)->findOrEmpty();
        if ($member->isEmpty() && !empty($user['mobile'])) {
            $member = Member::where('mobile', $user['mobile'])
                ->where('user_id', 0)
                ->findOrEmpty();
        }

        $user['channel'] = UserTerminalEnum::getTermInalDesc($user['channel']);
        $user->sex = $user->getData('sex');
        return array_merge($user->toArray(), [
            'email' => $member['email'] ?? '',
            'nationality' => $member['nationality'] ?? '日本',
            'postal_code' => $member['postal_code'] ?? '',
            'address' => $member['address'] ?? '',
            'building_name' => $member['building_name'] ?? '',
        ]);
    }


    /**
     * @notes 更新用户信息
     * @param array $params
     * @return User
     * @author 段誉
     * @date 2022/9/22 16:38
     */
    public static function setUserInfo(array $params)
    {
        $profileFields = ['email', 'nationality', 'postal_code', 'address', 'building_name'];
        if (in_array($params['field'], $profileFields, true)) {
            $member = Member::where('user_id', (int)$params['id'])->findOrEmpty();
            if ($member->isEmpty()) {
                $user = User::findOrEmpty((int)$params['id']);
                $member = Member::where('mobile', $user['mobile'] ?? '')
                    ->where('user_id', 0)
                    ->findOrEmpty();
            }
            if ($member->isEmpty()) {
                return false;
            }
            return Member::update([
                'id' => $member['id'],
                $params['field'] => $params['value'],
                'update_time' => time(),
            ]);
        }

        $value = $params['value'];
        if ($params['field'] === 'avatar') {
            $value = FileService::setFileUrl($value);
        }

        $result = User::update([
            'id' => $params['id'],
            $params['field'] => $value
        ]);
        if ($params['field'] === 'mobile') {
            Member::where('user_id', (int)$params['id'])->update([
                'mobile' => $params['value'],
                'update_time' => time(),
            ]);
        }
        return $result;
    }


    /**
     * @notes 调整用户余额
     * @param array $params
     * @return bool|string
     * @author 段誉
     * @date 2023/2/23 14:25
     */
    public static function adjustUserMoney(array $params)
    {
        Db::startTrans();
        try {
            $user = User::find($params['user_id']);
            if (AccountLogEnum::INC == $params['action']) {
                //调整可用余额
                $user->user_money += $params['num'];
                $user->save();
                //记录日志
                AccountLogLogic::add(
                    $user->id,
                    AccountLogEnum::UM_INC_ADMIN,
                    AccountLogEnum::INC,
                    $params['num'],
                    '',
                    $params['remark'] ?? ''
                );
            } else {
                $user->user_money -= $params['num'];
                $user->save();
                //记录日志
                AccountLogLogic::add(
                    $user->id,
                    AccountLogEnum::UM_DEC_ADMIN,
                    AccountLogEnum::DEC,
                    $params['num'],
                    '',
                    $params['remark'] ?? ''
                );
            }

            Db::commit();
            return true;

        } catch (\Exception $e) {
            Db::rollback();
            return $e->getMessage();
        }
    }

}
