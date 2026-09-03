import 'package:dio/dio.dart';

import '../config/app_config.dart';

class PaymentApi {
  PaymentApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  Future<List<PaymentMethodData>> fetchMethods({required String token}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/cabakura_payment/lists',
      options: Options(headers: {'token': token}),
    );
    final body = response.data ?? const <String, dynamic>{};
    final data = body['data'];
    final lists = data is Map ? data['lists'] : null;
    if (body['code'] != 1 || lists is! List) return const [];
    return lists
        .whereType<Map>()
        .map(
          (item) => PaymentMethodData.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> createCard({
    required String token,
    required String cardNumber,
    required String expiry,
    required String cvc,
    required String holderName,
    required bool isDefault,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/cabakura_payment/create',
      data: {
        'card_number': cardNumber,
        'expiry': expiry,
        'cvc': cvc,
        'holder_name': holderName,
        'is_default': isDefault ? 1 : 0,
      },
      options: Options(headers: {'token': token}),
    );
    final body = response.data ?? const <String, dynamic>{};
    if (body['code'] != 1) throw Exception(body['msg'] ?? 'カードを保存できませんでした');
  }
}

class PaymentMethodData {
  const PaymentMethodData({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.holderName,
    required this.isDefault,
  });

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) =>
      PaymentMethodData(
        id: (json['id'] as num?)?.toInt() ?? 0,
        brand: '${json['brand'] ?? 'CARD'}',
        last4: '${json['last4'] ?? ''}',
        expiry: '${json['expiry'] ?? ''}',
        holderName: '${json['holder_name'] ?? ''}',
        isDefault: json['is_default'] == 1 || json['is_default'] == true,
      );

  final int id;
  final String brand;
  final String last4;
  final String expiry;
  final String holderName;
  final bool isDefault;
}
