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
namespace app\api\validate;


use app\common\model\user\User;
use app\common\validate\BaseValidate;

/**
 * 注册验证器
 * Class RegisterValidate
 * @package app\api\validate
 */
class RegisterValidate extends BaseValidate
{

    protected $regex = [
        'register' => '^[0-9]{8,20}$',
        'password' => '/^[A-Za-z0-9]{6,20}$/'
    ];

    protected $rule = [
        'channel' => 'require',
        'account' => 'require|length:8,20|unique:' . User::class . '|regex:register',
        'password' => 'require|length:6,20|regex:password',
        'password_confirm' => 'require|confirm'
    ];

    protected $message = [
        'channel.require' => '登録元が指定されていません',
        'account.require' => '電話番号を入力してください',
        'account.regex' => '正しい電話番号を入力してください',
        'account.length' => '電話番号は8〜20桁で入力してください',
        'account.unique' => 'この電話番号はすでに登録されています',
        'password.require' => 'パスワードを入力してください',
        'password.length' => 'パスワードは6〜20文字で入力してください',
        'password.regex' => 'パスワードは半角英数字で入力してください',
        'password_confirm.require' => '確認用パスワードを入力してください',
        'password_confirm.confirm' => 'パスワードが一致しません'
    ];

    /**
     * @notes 注册手机号校验
     * @return RegisterValidate
     */
    public function sceneMobile()
    {
        return $this->only(['account']);
    }

}
