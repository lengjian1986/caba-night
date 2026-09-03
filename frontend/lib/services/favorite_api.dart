import 'package:dio/dio.dart';

import '../config/app_config.dart';

class FavoriteApi {
  FavoriteApi({Dio? dio})
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

  Future<bool> fetchStatus({required String token, required int shopId}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/cabakura_favorite/status',
      queryParameters: {'shop_id': shopId},
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    return response.data?['code'] == 1 &&
        data is Map &&
        (data['favorited'] == true || data['favorited'] == 1);
  }

  Future<bool> toggle({required String token, required int shopId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/cabakura_favorite/toggle',
      data: {'shop_id': shopId},
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    if (response.data?['code'] != 1 || data is! Map) {
      throw Exception(response.data?['msg'] ?? 'お気に入りを更新できませんでした');
    }
    return data['favorited'] == true || data['favorited'] == 1;
  }

  Future<List<Map<String, dynamic>>> fetchShops({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/cabakura_favorite/lists',
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    final lists = data is Map ? data['lists'] : null;
    if (response.data?['code'] != 1 || lists is! List) return const [];
    return lists
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<bool> fetchCastStatus({
    required String token,
    required int castId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/cabakura_favorite/castStatus',
      queryParameters: {'cast_id': castId},
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    return response.data?['code'] == 1 &&
        data is Map &&
        (data['favorited'] == true || data['favorited'] == 1);
  }

  Future<bool> toggleCast({required String token, required int castId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/cabakura_favorite/castToggle',
      data: {'cast_id': castId},
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    if (response.data?['code'] != 1 || data is! Map) {
      throw Exception(response.data?['msg'] ?? 'お気に入りを更新できませんでした');
    }
    return data['favorited'] == true || data['favorited'] == 1;
  }

  Future<List<Map<String, dynamic>>> fetchCasts({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/cabakura_favorite/castLists',
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    final lists = data is Map ? data['lists'] : null;
    if (response.data?['code'] != 1 || lists is! List) return const [];
    return lists
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
