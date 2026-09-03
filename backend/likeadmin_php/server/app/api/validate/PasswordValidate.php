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

use app\common\validate\BaseValidate;

/**
 * 密码校验
 * Class PasswordValidate
 * @package app\api\validate
 */
class PasswordValidate extends BaseValidate
{
    protected $regex = [
        'mobile' => '^[0-9]{8,20}$',
    ];

    protected $rule = [
        'old_password' => 'require',
        'mobile' => 'require|length:8,20|regex:mobile',
        'code' => 'require',
        'password' => 'require|length:6,20|alphaNum',
        'password_confirm' => 'require|confirm',
    ];


    protected $message = [
        'mobile.require' => '電話番号を入力してください',
        'mobile.length' => '電話番号は8〜20桁で入力してください',
        'mobile.regex' => '正しい電話番号を入力してください',
        'old_password.require' => '現在のパスワードを入力してください',
        'code.require' => '認証コードを入力してください',
        'password.require' => 'パスワードを入力してください',
        'password.length' => 'パスワードは6〜20文字で入力してください',
        'password.alphaNum' => 'パスワードは半角英数字で入力してください',
        'password_confirm.require' => '確認用パスワードを入力してください',
        'password_confirm.confirm' => 'パスワードが一致しません'
    ];


    /**
     * @notes 重置登录密码
     * @return PasswordValidate
     * @author 段誉
     * @date 2022/9/16 18:11
     */
    public function sceneResetPassword()
    {
        return $this->only(['mobile', 'code', 'password', 'password_confirm']);
    }


    /**
     * @notes 修改密码场景
     * @return PasswordValidate
     * @author 段誉
     * @date 2022/9/20 19:14
     */
    public function sceneChangePassword()
    {
        return $this->only(['old_password', 'password', 'password_confirm']);
    }

}
