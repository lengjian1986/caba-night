import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException(this.message);

  final String message;
}

class AuthApi {
  AuthApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

  final Dio _dio;

  Future<UserProfile> fetchProfile({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/user/center',
      options: Options(headers: {'token': token}),
    );
    final body = response.data ?? const <String, dynamic>{};
    final payload = body['data'];
    final code = body['code']?.toString();
    final message = body['msg'] ?? body['message'] ?? '';
    if (code == '-1' ||
        (code == '0' &&
            message is String &&
            (message.contains('登录超时') || message.contains('登录过期')))) {
      throw SessionExpiredException('別の端末でログインしたため、この端末はログアウトされました');
    }
    if (body['code'] != 1 || payload is! Map<String, dynamic>) {
      throw Exception(body['msg'] ?? body['message'] ?? 'ユーザー情報を取得できませんでした');
    }
    return UserProfile.fromJson(payload);
  }

  Future<void> saveMemberProfile({
    required String nickname,
    required String realName,
    required String email,
    required String nationality,
    required String postalCode,
    required String address,
    required String buildingName,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/saveCabakuraMemberProfile',
      options: Options(headers: {'token': token}),
      data: {
        'nickname': nickname,
        'real_name': realName,
        'email': email,
        'nationality': nationality,
        'postal_code': postalCode,
        'address': address,
        'building_name': buildingName,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? '会员资料保存失败');
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/upload/image',
      options: Options(headers: {'token': token}),
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final body = response.data ?? const <String, dynamic>{};
    final payload = body['data'];
    final url = payload is Map<String, dynamic>
        ? (payload['url'] ?? payload['uri'])
        : null;
    if (body['code'] != 1 || url is! String || url.isEmpty) {
      throw Exception(body['msg'] ?? body['message'] ?? '头像上传失败');
    }
    return url;
  }

  Future<void> saveAvatar({
    required String avatar,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/setInfo',
      options: Options(headers: {'token': token}),
      data: {'field': 'avatar', 'value': avatar},
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? '头像保存失败');
    }
  }

  Future<void> sendSmsCode({
    required String mobile,
    required String scene,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sms/sendCode',
      data: {'mobile': mobile, 'scene': scene},
    );
    if (response.data?['code'] != 1)
      throw Exception(response.data?['msg'] ?? '認証コードを送信できませんでした');
  }

  Future<void> checkRegisterMobile({required String mobile}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/login/checkRegisterMobile',
      data: {'account': mobile},
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? '電話番号を確認できませんでした');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirm,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/changePassword',
      options: Options(headers: {'token': token}),
      data: {
        'old_password': oldPassword,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? 'パスワードを変更できませんでした');
    }
  }

  Future<void> resetPassword({
    required String mobile,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/resetPassword',
      data: {
        'mobile': mobile,
        'code': code,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? 'パスワードを再設定できませんでした');
    }
  }

  Future<void> deleteAccount({
    required String reason,
    required String reuseApp,
    required String feedback,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/deleteAccount',
      options: Options(headers: {'token': token}),
      data: {'reason': reason, 'reuse_app': reuseApp, 'feedback': feedback},
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? 'アカウントを削除できませんでした');
    }
  }

  Future<void> changeMobile({
    required String oldMobile,
    required String mobile,
    required String code,
    required String token,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/user/bindMobile',
      data: {'old_mobile': oldMobile, 'mobile': mobile, 'code': code},
      options: Options(headers: {'token': token}),
    );
    if (response.data?['code'] != 1)
      throw Exception(response.data?['msg'] ?? '携帯番号を変更できませんでした');
  }

  Future<void> register({
    required String account,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/login/register',
      data: {
        'channel': 0,
        'account': account,
        'password': password,
        'password_confirm': password,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) {
      throw Exception(body['msg'] ?? body['message'] ?? '登録に失敗しました');
    }
  }

  Future<String> login({
    required String account,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/login/account',
      data: {
        'terminal': 4,
        'scene': 1,
        'account': account,
        'password': password,
      },
    );
    final body = response.data ?? const <String, dynamic>{};
    final payload = body['data'];
    if (body['code'] != 1 || payload is! Map<String, dynamic>) {
      throw Exception(body['msg'] ?? body['message'] ?? 'ログインに失敗しました');
    }

    final token = payload['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('ログイン情報を取得できませんでした');
    }
    return token;
  }
}

class UserProfile {
  const UserProfile({
    required this.nickname,
    required this.realName,
    required this.mobile,
    required this.email,
    required this.nationality,
    required this.postalCode,
    required this.address,
    required this.buildingName,
    required this.avatar,
    required this.levelName,
    required this.walletBalance,
    required this.benefits,
    required this.benefitDescription,
    required this.expiration,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      nickname: (json['nickname'] as String? ?? '').trim(),
      realName: (json['real_name'] as String? ?? '').trim(),
      mobile: (json['mobile'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      nationality: (json['nationality'] as String? ?? '日本').trim(),
      postalCode: (json['postal_code'] as String? ?? '').trim(),
      address: (json['address'] as String? ?? '').trim(),
      buildingName: (json['building_name'] as String? ?? '').trim(),
      avatar: (json['avatar'] as String? ?? '').trim(),
      levelName: (json['level_name'] as String? ?? '一般会員').trim(),
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
      benefits: (json['member_benefits'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      benefitDescription:
          (json['member_benefit_description'] as String? ?? '特典なし').trim(),
      expiration: (json['member_expiration'] as String? ?? '無期限').trim(),
    );
  }

  final String nickname,
      realName,
      mobile,
      email,
      nationality,
      postalCode,
      address,
      buildingName;
  final String avatar;
  final String levelName;
  final double walletBalance;
  final List<String> benefits;
  final String benefitDescription;
  final String expiration;

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'real_name': realName,
    'mobile': mobile,
    'email': email,
    'nationality': nationality,
    'postal_code': postalCode,
    'address': address,
    'building_name': buildingName,
    'avatar': avatar,
    'level_name': levelName,
    'wallet_balance': walletBalance,
    'member_benefits': benefits,
    'member_benefit_description': benefitDescription,
    'member_expiration': expiration,
  };
}
