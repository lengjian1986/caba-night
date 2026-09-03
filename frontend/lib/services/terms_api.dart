import 'package:dio/dio.dart';

import '../config/app_config.dart';

class TermsApi {
  TermsApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final Dio _dio;

  Future<List<TermData>> fetchTerms({required String token}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_terms/lists',
        options: Options(headers: {'token': token}),
      );
      final data = response.data?['data'];
      final lists = data is Map ? data['lists'] : null;
      if (lists is List) {
        return lists
            .whereType<Map>()
            .map((item) => TermData.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}

class TermData {
  const TermData({
    required this.name,
    required this.title,
    required this.content,
  });
  factory TermData.fromJson(Map<String, dynamic> json) => TermData(
    name: '${json['name'] ?? ''}',
    title: '${json['title'] ?? ''}',
    content: '${json['content'] ?? ''}',
  );
  final String name, title, content;
}
