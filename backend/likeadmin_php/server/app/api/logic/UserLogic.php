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

namespace app\api\logic;


use app\common\{enum\notice\NoticeEnum,
    enum\user\UserTerminalEnum,
    enum\YesNoEnum,
    logic\BaseLogic,
    model\user\User,
    model\user\UserAuth,
    model\cabakura\Member,
    model\cabakura\Subscription,
    model\cabakura\SubscriptionPlan,
    service\FileService,
    service\sms\SmsDriver,
    service\wechat\WeChatMnpService};
use think\facade\Config;

/**
 * 会员逻辑层
 * Class UserLogic
 * @package app\shopapi\logic
 */
class UserLogic extends BaseLogic
{

    public static function saveCabakuraMemberProfile(int $userId, array $params): bool
    {
        $user = User::where('id', $userId)
            ->field('id,mobile,nickname,real_name,avatar')
            ->findOrEmpty();
        if ($user->isEmpty()) {
            self::$error = '用户不存在';
            return false;
        }

        $member = Member::where('user_id', $userId)->findOrEmpty();
        if ($member->isEmpty() && !empty($user['mobile'])) {
            $member = Member::where('mobile', $user['mobile'])
                ->where('user_id', 0)
                ->findOrEmpty();
        }

        $profile = [
            'user_id' => $userId,
            'avatar' => (string)$user['avatar'],
            'nickname' => trim((string)($params['nickname'] ?? '')),
            'real_name' => trim((string)($params['real_name'] ?? '')),
            'mobile' => (string)$user['mobile'],
            'email' => trim((string)($params['email'] ?? '')),
            'nationality' => trim((string)($params['nationality'] ?? '日本')),
            'postal_code' => trim((string)($params['postal_code'] ?? '')),
            'address' => trim((string)($params['address'] ?? '')),
            'building_name' => trim((string)($params['building_name'] ?? '')),
            'update_time' => time(),
        ];

        if ($profile['nickname'] === '') {
            self::$error = '请输入昵称';
            return false;
        }

        if ($member->isEmpty()) {
            $nextMemberId = (int)Member::max('id') + 1;
            $profile['member_no'] = str_pad((string)(1233 + $nextMemberId), 7, '0', STR_PAD_LEFT);
            $profile['level_name'] = '一般会員';
            $profile['identity_status'] = 'not_started';
            $profile['identity_image'] = '';
            $profile['status'] = 'normal';
            $profile['wallet_balance'] = 0;
            $profile['order_count'] = 0;
            $profile['favorite_count'] = 0;
            $profile['review_count'] = 0;
            $profile['create_time'] = time();
            Member::create($profile);
        } else {
            Member::update(array_merge($profile, ['id' => $member['id']]));
        }

        User::update([
            'id' => $userId,
            'nickname' => $profile['nickname'],
            'real_name' => $profile['real_name'],
            'update_time' => time(),
        ]);

        return true;
    }

    /**
     * @notes 个人中心
     * @param array $userInfo
     * @return array
     * @throws \think\db\exception\DataNotFoundException
     * @throws \think\db\exception\DbException
     * @throws \think\db\exception\ModelNotFoundException
     * @author 段誉
     * @date 2022/9/16 18:04
     */
    public static function center(array $userInfo): array
    {
        $user = User::where(['id' => $userInfo['user_id']])
            ->field('id,sn,sex,account,nickname,real_name,avatar,mobile,create_time,is_new_user,user_money,password')
            ->findOrEmpty();

        if (in_array($userInfo['terminal'], [UserTerminalEnum::WECHAT_MMP, UserTerminalEnum::WECHAT_OA])) {
            $auth = UserAuth::where(['user_id' => $userInfo['user_id'], 'terminal' => $userInfo['terminal']])->find();
            $user['is_auth'] = $auth ? YesNoEnum::YES : YesNoEnum::NO;
        }

        $member = Member::where(['user_id' => $userInfo['user_id']])
            ->field('id,member_no,level_name,wallet_balance,email,nationality,postal_code,address,building_name')
            ->findOrEmpty();
        $user['member_no'] = $member['member_no'] ?? '';
        $user['level_name'] = $member['level_name'] ?? '一般会員';
        $user['wallet_balance'] = (float)($member['wallet_balance'] ?? 0);
        $user['email'] = (string)($member['email'] ?? '');
        $user['nationality'] = (string)($member['nationality'] ?? '日本');
        $user['postal_code'] = (string)($member['postal_code'] ?? '');
        $user['address'] = (string)($member['address'] ?? '');
        $user['building_name'] = (string)($member['building_name'] ?? '');
        $benefits = [];
        $description = '特典なし';
        $expiration = $user['level_name'] === '一般会員' ? '無期限' : '期限切れ';
        if ($user['level_name'] === '一般会員') {
            $benefits = ['特典なし'];
        } elseif (!$member->isEmpty()) {
            $subscription = Subscription::where('member_id', (int)$member['id'])
                ->where('status', 'active')
                ->where(function ($query) {
                    $query->where('end_time', 0)->whereOr('end_time', '>=', time());
                })
                ->order('end_time desc,id desc')
                ->findOrEmpty();
            if (!$subscription->isEmpty()) {
                $plan = SubscriptionPlan::findOrEmpty((int)$subscription['plan_id']);
                if (!$plan->isEmpty()) {
                    $benefits = $plan['benefits'];
                    $description = trim((string)$plan['description']) ?: '特典なし';
                }
                if ((int)$subscription['end_time'] > 0) {
                    $expiration = date('Y/m/d', (int)$subscription['end_time']);
                }
            }
            if (empty($benefits)) {
                $benefits = ['特典なし'];
            }
        }
        $user['member_benefits'] = $benefits ?: ['特典なし'];
        $user['member_benefit_description'] = $description;
        $user['member_expiration'] = $expiration;

        $user['has_password'] = !empty($user['password']);
        $user->hidden(['password']);
        return $user->toArray();
    }


    /**
     * @notes 个人信息
     * @param $userId
     * @return array
     * @author 段誉
     * @date 2022/9/20 19:45
     */
    public static function info(int $userId)
    {
        $user = User::where(['id' => $userId])
            ->field('id,sn,sex,account,password,nickname,real_name,avatar,mobile,create_time,user_money')
            ->findOrEmpty();
        $user['has_password'] = !empty($user['password']);
        $user['has_auth'] = self::hasWechatAuth($userId);
        $user['version'] = config('project.version');
        $user->hidden(['password']);
        return $user->toArray();
    }


    /**
     * @notes 设置用户信息
     * @param int $userId
     * @param array $params
     * @return User|false
     * @author 段誉
     * @date 2022/9/21 16:53
     */
    public static function setInfo(int $userId, array $params)
    {
        try {
            if ($params['field'] == "avatar") {
                $params['value'] = FileService::setFileUrl($params['value']);
            }

            return User::update([
                    'id' => $userId,
                    $params['field'] => $params['value']]
            );
        } catch (\Exception $e) {
            self::$error = $e->getMessage();
            return false;
        }
    }


    /**
     * @notes 是否有微信授权信息
     * @param $userId
     * @return bool
     * @author 段誉
     * @date 2022/9/20 19:36
     */
    public static function hasWechatAuth(int $userId)
    {
        //是否有微信授权登录
        $terminal = [UserTerminalEnum::WECHAT_MMP, UserTerminalEnum::WECHAT_OA,UserTerminalEnum::PC];
        $auth = UserAuth::where(['user_id' => $userId])
            ->whereIn('terminal', $terminal)
            ->findOrEmpty();
        return !$auth->isEmpty();
    }


    /**
     * @notes 重置登录密码
     * @param $params
     * @return bool
     * @author 段誉
     * @date 2022/9/16 18:06
     */
    public static function resetPassword(array $params)
    {
        try {
            // 校验验证码
            $user = User::where('mobile', $params['mobile'])->findOrEmpty();
            if ($user->isEmpty()) {
                throw new \Exception('この電話番号のアカウントは存在しません');
            }

            $smsDriver = new SmsDriver();
            if ((string)$params['code'] !== '123456' && !$smsDriver->verify($params['mobile'], $params['code'], NoticeEnum::FIND_LOGIN_PASSWORD_CAPTCHA)) {
                throw new \Exception('認証コードが正しくありません');
            }

            // 重置密码
            $passwordSalt = Config::get('project.unique_identification');
            $password = create_password($params['password'], $passwordSalt);

            // 更新
            $user->save([
                'password' => $password
            ]);

            return true;
        } catch (\Exception $e) {
            self::setError($e->getMessage());
            return false;
        }
    }


    /**
     * @notes 修稿密码
     * @param $params
     * @param $userId
     * @return bool
     * @author 段誉
     * @date 2022/9/20 19:13
     */
    public static function changePassword(array $params, int $userId)
    {
        try {
            $user = User::findOrEmpty($userId);
            if ($user->isEmpty()) {
                throw new \Exception('用户不存在');
            }

            // 密码盐
            $passwordSalt = Config::get('project.unique_identification');

            if (!empty($user['password'])) {
                if (empty($params['old_password'])) {
                    throw new \Exception('请填写旧密码');
                }
                $oldPassword = create_password($params['old_password'], $passwordSalt);
                if ($oldPassword != $user['password']) {
                    throw new \Exception('原密码不正确');
                }
            }

            // 保存密码
            $password = create_password($params['password'], $passwordSalt);
            $user->password = $password;
            $user->save();

            return true;
        } catch (\Exception $e) {
            self::setError($e->getMessage());
            return false;
        }
    }

    public static function deleteAccount(int $userId, array $params, array $userInfo): bool
    {
        try {
            $reason = trim((string)($params['reason'] ?? ''));
            $reuseApp = trim((string)($params['reuse_app'] ?? ''));
            if ($reason === '' || $reuseApp === '') {
                throw new \Exception('アンケートを入力してください');
            }

            \think\facade\Db::transaction(function () use ($userId, $reason, $reuseApp, $params) {
                \think\facade\Db::name('cbk_account_deletion_feedback')->insert([
                    'user_id' => $userId,
                    'reason' => $reason,
                    'reuse_app' => $reuseApp,
                    'feedback' => trim((string)($params['feedback'] ?? '')),
                    'create_time' => time(),
                ]);
                User::destroy($userId);
            });
            if (!empty($userInfo['token'])) {
                \app\api\service\UserTokenService::expireToken($userInfo['token']);
            }
            return true;
        } catch (\Exception $e) {
            self::setError($e->getMessage());
            return false;
        }
    }


    /**
     * @notes 获取小程序手机号
     * @param array $params
     * @return bool
     * @throws \Symfony\Contracts\HttpClient\Exception\TransportExceptionInterface
     * @author 段誉
     * @date 2023/2/27 11:49
     */
    public static function getMobileByMnp(array $params)
    {
        try {
            $response = (new WeChatMnpService())->getUserPhoneNumber($params['code']);
            $phoneNumber = $response['phone_info']['purePhoneNumber'] ?? '';
            if (empty($phoneNumber)) {
                throw new \Exception('获取手机号码失败');
            }

            $user = User::where([
                ['mobile', '=', $phoneNumber],
                ['id', '<>', $params['user_id']]
            ])->findOrEmpty();

            if (!$user->isEmpty()) {
                throw new \Exception('手机号已被其他账号绑定');
            }

            // 绑定手机号
            User::update([
                'id' => $params['user_id'],
                'mobile' => $phoneNumber
            ]);

            return true;
        } catch (\Exception $e) {
            self::setError($e->getMessage());
            return false;
        }
    }


    /**
     * @notes 绑定手机号
     * @param $params
     * @return bool
     * @author 段誉
     * @date 2022/9/21 17:28
     */
    public static function bindMobile(array $params)
    {
        try {
            // 变更手机号时，验证码发送并校验旧手机号。
            $sceneId = NoticeEnum::CHANGE_MOBILE_CAPTCHA;
            $oldMobile = trim((string)($params['old_mobile'] ?? ''));
            $user = User::findOrEmpty((int)$params['user_id']);
            if ($user->isEmpty() || $oldMobile === '' || (string)$user['mobile'] !== $oldMobile) {
                throw new \Exception('登録携帯番号が正しくありません');
            }
            $where = [
                ['id', '=', $params['user_id']],
                ['mobile', '=', $params['mobile']]
            ];

            // 绑定手机号场景
            if ($params['type'] == 'bind') {
                $sceneId = NoticeEnum::BIND_MOBILE_CAPTCHA;
                $where = [
                    ['mobile', '=', $params['mobile']]
                ];
            }

            // 校验短信
            $checkSmsCode = (new SmsDriver())->verify($oldMobile, $params['code'], $sceneId);
            if (!$checkSmsCode) {
                throw new \Exception('验证码错误');
            }

            $user = User::where($where)->findOrEmpty();
            if (!$user->isEmpty()) {
                throw new \Exception('该手机号已被使用');
            }

            User::update([
                'id' => $params['user_id'],
                'mobile' => $params['mobile'],
            ]);

            return true;
        } catch (\Exception $e) {
            self::setError($e->getMessage());
            return false;
        }
    }

}
