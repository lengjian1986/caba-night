import 'package:dio/dio.dart';

import '../config/app_config.dart';

class SupportApi {
  SupportApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  final Dio _dio;

  Future<SupportConversation> fetchLatest({required String token}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_support/latest',
        options: Options(headers: {'token': token}),
      );
      final data = response.data?['data'];
      if (data is Map)
        return SupportConversation.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {}
    return const SupportConversation.empty();
  }

  Future<void> markRead({required String token}) async {
    try {
      await _dio.post(
        '/api/cabakura_support/read',
        options: Options(headers: {'token': token}),
      );
    } catch (_) {}
  }

  Future<SupportConversation?> send({
    required String token,
    required String category,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/cabakura_support/send',
        data: {'category': category, 'content': content},
        options: Options(headers: {'token': token}),
      );
      final data = response.data?['data'];
      if (data is Map)
        return SupportConversation.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {}
    return null;
  }
}

class SupportConversation {
  const SupportConversation({
    required this.messages,
    this.ticketNo = '',
    this.unreadCount = 0,
  });
  const SupportConversation.empty()
    : messages = const [],
      ticketNo = '',
      unreadCount = 0;
  factory SupportConversation.fromJson(Map<String, dynamic> json) =>
      SupportConversation(
        ticketNo: '${(json['ticket'] as Map?)?['ticket_no'] ?? ''}',
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        messages: (json['messages'] is List)
            ? (json['messages'] as List)
                  .whereType<Map>()
                  .map(
                    (item) => SupportMessage.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList()
            : const [],
      );
  final String ticketNo;
  final int unreadCount;
  final List<SupportMessage> messages;
}

class SupportMessage {
  const SupportMessage({required this.content, required this.senderType});
  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    content: '${json['content'] ?? ''}',
    senderType: '${json['sender_type'] ?? 'member'}',
  );
  final String content, senderType;
}
