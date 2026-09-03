import 'package:dio/dio.dart';

import '../config/app_config.dart';

class NoticeApi {
  NoticeApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final Dio _dio;

  Future<List<NoticeItem>> fetchNotices({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/notice/lists',
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    final lists = data is Map ? data['lists'] : null;
    if (lists is! List) return const [];
    return lists
        .whereType<Map>()
        .map((item) => NoticeItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<int> fetchUnreadCount({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/notice/lists',
      options: Options(headers: {'token': token}),
    );
    final data = response.data?['data'];
    if (data is! Map) return 0;
    return int.tryParse('${data['unread_count'] ?? 0}') ?? 0;
  }

  Future<void> readAll({required String token}) async {
    await _dio.post(
      '/api/notice/readAll',
      options: Options(headers: {'token': token}),
    );
  }
}

class NoticeItem {
  const NoticeItem({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.read,
  });
  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
    title: '${json['title'] ?? ''}',
    content: '${json['content'] ?? ''}',
    createdAt: '${json['create_time_text'] ?? ''}',
    read: '${json['read'] ?? 0}' == '1',
  );
  final String title, content, createdAt;
  final bool read;
}
