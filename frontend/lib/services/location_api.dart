import 'package:dio/dio.dart';

import '../config/app_config.dart';

class LocationApi {
  LocationApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  Future<String?> resolveArea({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_home/location',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      final data = response.data?['data'];
      if (data is Map &&
          data['area'] is String &&
          (data['area'] as String).isNotEmpty) {
        return data['area'] as String;
      }
    } catch (_) {}
    return null;
  }
}
