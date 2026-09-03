# Face ID 实现记录

## 当前状态

已写入 Flutter 原生认证接入代码。当前 Web 端使用兼容占位实现，不调用浏览器生物识别；打包 iOS 后会调用系统 Face ID。

## 已完成

- 设置页的 `Face IDでログイン` 开关已连接认证服务。
- 开启时先调用系统 Face ID，认证成功后将当前登录 token 保存到 iOS Keychain。
- 关闭时删除 Face ID 登录开关和 Keychain 中保存的 token。
- App 启动时，如果已开启 Face ID，会先请求 Face ID，成功后恢复登录。
- iOS 已添加 `NSFaceIDUsageDescription` 权限说明。
- 使用 `local_auth` 调用本机生物认证，使用 `flutter_secure_storage` 保存敏感凭证。

## iOS 测试条件

1. 执行 `flutter pub get`。
2. 使用真实 iPhone 打包运行，设备必须支持 Face ID 且已经录入 Face ID。
3. 首次登录后进入「マイページ > 設定 > セキュリティ設定」，打开 `Face IDでログイン`。
4. 认证成功后关闭 App 再打开，确认会先出现 Face ID 验证。
5. 在另一端登录使旧 token 失效后，Face ID 恢复的 token 也会被后端会话检查识别并要求重新登录。

## 注意事项

- Web 端不会执行真实 Face ID，开关仅保留兼容行为。
- 当前保存的是后端登录 token，不保存密码。
- token 过期、被其他端登录替换或用户关闭 Face ID 时，需要重新登录并重新开启 Face ID。
- 发布前应在真实 iPhone 上测试首次授权、取消授权、Face ID 失败、设备未设置 Face ID 和系统权限关闭等场景。
