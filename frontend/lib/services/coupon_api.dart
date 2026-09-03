import 'package:dio/dio.dart';

import '../config/app_config.dart';

class CouponApi {
  CouponApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final Dio _dio;

  Future<List<CouponData>> fetchCoupons({required String token}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_coupon/lists',
        options: Options(headers: {'token': token}),
      );
      final lists = response.data?['data'] is Map
          ? (response.data?['data'] as Map)['lists']
          : null;
      if (lists is List)
        return lists
            .whereType<Map>()
            .map((item) => CouponData.fromJson(Map<String, dynamic>.from(item)))
            .toList();
    } catch (_) {}
    return const [];
  }
}

class CouponData {
  const CouponData({
    required this.code,
    required this.name,
    required this.description,
    required this.logoImage,
    required this.discountType,
    required this.discountValue,
    required this.status,
    required this.expireTime,
  });
  factory CouponData.fromJson(Map<String, dynamic> json) => CouponData(
    code: '${json['coupon_code'] ?? ''}',
    name: '${json['name'] ?? ''}',
    description: '${json['description'] ?? ''}',
    logoImage: '${json['logo_image'] ?? ''}',
    discountType: '${json['discount_type'] ?? 'fixed'}',
    discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
    status: '${json['status'] ?? 'available'}',
    expireTime: '${json['expire_time_text'] ?? ''}',
  );
  final String code,
      name,
      description,
      logoImage,
      discountType,
      status,
      expireTime;
  final int discountValue;
}
