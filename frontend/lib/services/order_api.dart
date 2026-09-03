import 'package:dio/dio.dart';

import '../config/app_config.dart';

class OrderApi {
  OrderApi({Dio? dio})
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

  Future<List<Map<String, dynamic>>> fetchMyOrders({
    required String token,
  }) async {
    if (token.isEmpty) return const [];
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_order/lists',
        options: Options(headers: {'token': token}),
      );
      final payload = response.data?['data'];
      final lists = payload is Map<String, dynamic> ? payload['lists'] : null;
      if (lists is List) {
        return lists.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<Map<String, dynamic>?> createReservation({
    required String shopName,
    required String castName,
    required int visitTime,
    required int peopleCount,
    required int amount,
    String token = '',
    String remark = '',
    String couponCode = '',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/cabakura_order/create',
        options: token.isEmpty ? null : Options(headers: {'token': token}),
        data: {
          'shop_name': shopName,
          'cast_name': castName,
          'visit_time': visitTime,
          'people_count': peopleCount,
          'amount': amount,
          'remark': remark,
          'coupon_code': couponCode,
        },
      );
      final payload = response.data?['data'];
      if (payload is Map<String, dynamic>) return payload;
    } catch (_) {}
    return null;
  }
}
