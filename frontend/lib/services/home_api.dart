import 'package:dio/dio.dart';

import '../config/app_config.dart';

class HomeApi {
  HomeApi({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          );

  final Dio _dio;

  Future<ShopDetailData?> fetchShopDetail(int shopId) async {
    if (shopId <= 0) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_home/detail',
        queryParameters: {'shop_id': shopId},
      );
      final payload = response.data?['data'];
      if (payload is Map<String, dynamic> && payload.isNotEmpty) {
        return ShopDetailData.fromJson(payload);
      }
    } catch (_) {}
    return null;
  }

  Future<List<CastScheduleData>> fetchCastSchedule(int castId) async {
    if (castId <= 0) return const [];
    final today = DateTime.now();
    final from = _dateKey(today);
    final toDate = today.add(const Duration(days: 30));
    final to = _dateKey(toDate);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_home/castSchedule',
        queryParameters: {'cast_id': castId, 'from': from, 'to': to},
      );
      final payload = response.data?['data'];
      if (payload is Map<String, dynamic>) {
        return _list(payload['schedules'], CastScheduleData.fromJson);
      }
    } catch (_) {}
    return const [];
  }

  Future<HomeViewData> fetchHome({
    String area = '',
    String keyword = '',
    String attendanceStatus = '',
    String sort = '',
    String shopFilter = '',
    String castSort = '',
    bool includeAreaTree = true,
    bool strictSearch = false,
  }) async {
    final normalizedArea = area == '全エリア' ? '' : area;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/cabakura_home/index',
        queryParameters: {
          if (normalizedArea.isNotEmpty) 'area': normalizedArea,
          if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
          if (attendanceStatus.isNotEmpty)
            'attendance_status': attendanceStatus,
          if (sort.isNotEmpty) 'sort': sort,
          if (shopFilter.isNotEmpty) 'shop_filter': shopFilter,
          if (castSort.isNotEmpty) 'cast_sort': castSort,
          if (includeAreaTree) 'area_tree': 1,
          if (strictSearch) 'strict_search': 1,
        },
      );
      final payload = response.data?['data'];
      if (payload is Map<String, dynamic>) {
        return HomeViewData.fromJson(payload, selectedArea: normalizedArea);
      }
    } catch (_) {
      // Keep the page usable while the backend contract is still being finalized.
    }

    return HomeViewData.empty(selectedArea: normalizedArea);
  }
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CastScheduleData {
  const CastScheduleData({
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.attendanceStatus,
  });

  factory CastScheduleData.fromJson(Map<String, dynamic> json) =>
      CastScheduleData(
        workDate: json['work_date'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        attendanceStatus: json['attendance_status'] as String? ?? 'scheduled',
      );

  final String workDate;
  final String startTime;
  final String endTime;
  final String attendanceStatus;
}

class HomeViewData {
  const HomeViewData({
    required this.area,
    required this.shops,
    required this.casts,
    required this.campaigns,
    required this.news,
    required this.areaOptions,
  });

  factory HomeViewData.fromJson(
    Map<String, dynamic> json, {
    String selectedArea = '',
  }) {
    final parsedAreaOptions = _list(json['area_tree'], AreaData.fromJson);
    final areaOptions = [
      const AreaData(id: 0, name: '全エリア'),
      ..._flattenAreaOptions(parsedAreaOptions),
    ];
    final currentArea = selectedArea.isNotEmpty ? selectedArea : '全エリア';

    return HomeViewData(
      area: currentArea,
      shops: _shopList(json['shops']),
      casts: _list(json['casts'], CastData.fromJson),
      campaigns: _list(
        json['campaigns'] ?? json['plans'],
        CampaignData.fromJson,
      ),
      news: _list(json['news'], NewsData.fromJson),
      areaOptions: areaOptions,
    );
  }

  factory HomeViewData.empty({String selectedArea = ''}) {
    return HomeViewData(
      area: selectedArea.isNotEmpty ? selectedArea : '東京都',
      shops: const [],
      casts: const [],
      campaigns: const [],
      news: const [],
      areaOptions: [
        const AreaData(id: 0, name: '全エリア'),
        if (selectedArea.isNotEmpty && selectedArea != '全エリア')
          AreaData(id: 0, name: selectedArea),
      ],
    );
  }

  factory HomeViewData.mock({String selectedArea = ''}) {
    return HomeViewData.empty(selectedArea: selectedArea);
  }

  final String area;
  final List<ShopData> shops;
  final List<CastData> casts;
  final List<CampaignData> campaigns;
  final List<NewsData> news;
  final List<AreaData> areaOptions;
}

class AreaData {
  const AreaData({
    required this.id,
    required this.name,
    this.children = const [],
  });

  factory AreaData.fromJson(Map<String, dynamic> json) {
    return AreaData(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      children: _list(json['children'], AreaData.fromJson),
    );
  }

  final int id;
  final String name;
  final List<AreaData> children;
}

List<AreaData> _flattenAreaOptions(List<AreaData> roots) {
  final result = <AreaData>[];
  for (final root in roots) {
    if (root.name.isEmpty) continue;
    result.add(AreaData(id: root.id, name: root.name));
    result.addAll(_flattenAreaChildren(root.children, root.name));
  }
  return result;
}

List<AreaData> _flattenAreaChildren(
  List<AreaData> children,
  String parentName,
) {
  final result = <AreaData>[];
  for (final child in children) {
    if (child.name.isEmpty) continue;
    final name = parentName.isEmpty ? child.name : '$parentName ${child.name}';
    result.add(AreaData(id: child.id, name: name));
    result.addAll(_flattenAreaChildren(child.children, name));
  }
  return result;
}

class ShopData {
  const ShopData({
    required this.id,
    required this.name,
    required this.area,
    required this.description,
    required this.address,
    required this.station,
    required this.isRecommended,
    required this.businessStatus,
    required this.businessHours,
    required this.bookingEnabled,
    required this.shopImages,
    required this.packageSets,
    required this.casts,
    required this.reviews,
    required this.price,
    required this.score,
    required this.count,
    required this.tags,
    required this.asset,
    required this.fallbackAsset,
    required this.rank,
    required this.ribbonColor,
    required this.isSearchFallback,
  });

  factory ShopData.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final fallbackAsset = _defaultShopAssets[index % _defaultShopAssets.length];
    final image = _resolveImageUrl(
      json['image'] as String? ?? json['cover_asset'] as String? ?? '',
    );
    final rating = json['rating'] ?? json['score'] ?? '4.8';
    final reviewCount = json['review_count'] ?? json['count'];
    final rawBusinessStatus = json['business_status'] as String? ?? '';

    return ShopData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      area: json['area'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      station: json['station'] as String? ?? '',
      businessHours: json['business_hours'] as String? ?? '',
      isRecommended:
          json['is_recommended'] == 1 || json['is_recommended'] == true,
      businessStatus: rawBusinessStatus == '営業中' ? '営業中' : '休み',
      price: json['price'] as String? ?? '',
      bookingEnabled:
          json['booking_enabled'] == 1 || json['booking_enabled'] == true,
      shopImages: _stringList(
        json['shop_images'],
      ).map(_resolveImageUrl).toList(),
      packageSets: (json['package_sets'] is List)
          ? List<Map<String, dynamic>>.from(
              (json['package_sets'] as List).whereType<Map>(),
            )
          : const [],
      casts: _list(json['casts'], CastData.fromJson),
      reviews: (json['reviews'] is List)
          ? List<Map<String, dynamic>>.from(
              (json['reviews'] as List).whereType<Map>(),
            )
          : const [],
      score: '$rating',
      count: reviewCount == null ? '' : '($reviewCount)',
      tags: _stringList(json['tags']),
      asset: image.isNotEmpty ? image : fallbackAsset,
      fallbackAsset: fallbackAsset,
      rank: '${json['rank'] ?? index + 1}',
      ribbonColor: _rankColor(index),
      isSearchFallback:
          json['is_search_fallback'] == true || json['is_search_fallback'] == 1,
    );
  }

  final String name;
  final int id;
  final String area;
  final String description;
  final String address;
  final String station;
  final bool isRecommended;
  final String businessStatus;
  final String businessHours;
  final bool bookingEnabled;
  final List<String> shopImages;
  final List<Map<String, dynamic>> packageSets;
  final List<CastData> casts;
  final List<Map<String, dynamic>> reviews;
  final String price;
  final String score;
  final String count;
  final List<String> tags;
  final String asset;
  final String fallbackAsset;
  final String rank;
  final int ribbonColor;
  final bool isSearchFallback;
}

class ShopDetailData {
  const ShopDetailData({
    required this.id,
    required this.name,
    required this.area,
    required this.description,
    required this.address,
    required this.station,
    required this.businessHours,
    required this.bookingEnabled,
    required this.priceRange,
    required this.businessStatus,
    required this.rating,
    required this.reviewCount,
    required this.images,
    required this.packageSets,
    required this.casts,
    required this.reviews,
  });

  factory ShopDetailData.fromJson(Map<String, dynamic> json) => ShopDetailData(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    area: json['area'] as String? ?? '',
    description: json['description'] as String? ?? '',
    address: json['address'] as String? ?? '',
    station: json['station'] as String? ?? '',
    businessHours: json['business_hours'] as String? ?? '',
    bookingEnabled:
        json['booking_enabled'] == 1 || json['booking_enabled'] == true,
    priceRange: json['price_range'] as String? ?? '',
    businessStatus: json['business_status'] as String? ?? '',
    rating: '${json['rating'] ?? ''}',
    reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    images: _stringList(json['shop_images']).map(_resolveImageUrl).toList(),
    packageSets: (json['package_sets'] is List)
        ? List<Map<String, dynamic>>.from(
            (json['package_sets'] as List).whereType<Map>(),
          )
        : const [],
    casts: _list(json['casts'], CastData.fromJson),
    reviews: (json['reviews'] is List)
        ? List<Map<String, dynamic>>.from(
            (json['reviews'] as List).whereType<Map>(),
          )
        : const [],
  );

  final int id;
  final String name;
  final String area;
  final String description;
  final String address;
  final String station;
  final String businessHours;
  final bool bookingEnabled;
  final String priceRange;
  final String businessStatus;
  final String rating;
  final int reviewCount;
  final List<String> images;
  final List<Map<String, dynamic>> packageSets;
  final List<CastData> casts;
  final List<Map<String, dynamic>> reviews;

  ShopDetailData copyWith({List<CastData>? casts}) => ShopDetailData(
    id: id,
    name: name,
    area: area,
    description: description,
    address: address,
    station: station,
    businessHours: businessHours,
    bookingEnabled: bookingEnabled,
    priceRange: priceRange,
    businessStatus: businessStatus,
    rating: rating,
    reviewCount: reviewCount,
    images: images,
    packageSets: packageSets,
    casts: casts ?? this.casts,
    reviews: reviews,
  );
}

class CastData {
  const CastData({
    this.id = 0,
    this.shopId = 0,
    required this.name,
    required this.shop,
    required this.area,
    this.shopImage = '',
    this.shopStatus = '',
    required this.rating,
    this.age = 0,
    required this.height,
    this.style = '',
    this.bloodType = '',
    this.birthplace = '',
    this.hobby = '',
    this.attendanceFrequency = '',
    this.preferredMaleType = '',
    this.smokingDrinking = '',
    this.profile = '',
    this.reviews = const [],
    this.galleryImages = const [],
    required this.tags,
    required this.isRecommended,
    required this.isNew,
    required this.isPopular,
    required this.badge,
    required this.button,
    required this.asset,
    required this.fallbackAsset,
    required this.color,
  });

  factory CastData.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? '出勤中';
    const fallbackAsset = 'assets/home/cast-rio-v1.png';
    final image = _resolveImageUrl(
      json['image'] as String? ??
          json['main_image'] as String? ??
          json['portrait_asset'] as String? ??
          json['cover_asset'] as String? ??
          '',
    );
    final tags = _stringList(json['tags']);

    return CastData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shopId: (json['shop_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      shop: json['shop'] as String? ?? '',
      area: json['area'] as String? ?? '',
      shopImage: _resolveImageUrl(json['shop_image'] as String? ?? ''),
      shopStatus: json['shop_business_status'] as String? ?? '',
      rating: '${json['rating'] ?? ''}',
      age: (json['age'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      style: json['style'] as String? ?? '',
      bloodType: json['blood_type'] as String? ?? '',
      birthplace: json['birthplace'] as String? ?? '',
      hobby: json['hobby'] as String? ?? '',
      attendanceFrequency: json['attendance_frequency'] as String? ?? '',
      preferredMaleType: json['preferred_male_type'] as String? ?? '',
      smokingDrinking: json['smoking_drinking'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      reviews: (json['reviews'] is List)
          ? List<Map<String, dynamic>>.from(
              (json['reviews'] as List).whereType<Map>(),
            )
          : const [],
      galleryImages: _stringList(
        json['gallery_images'],
      ).map(_resolveImageUrl).toList(),
      tags: tags,
      isRecommended:
          json['is_recommended'] == 1 || json['is_recommended'] == true,
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      isPopular: json['is_popular'] == 1 || json['is_popular'] == true,
      badge: json['badge'] as String? ?? status,
      button: tags.isNotEmpty ? tags.first : '—',
      asset: image.isNotEmpty ? image : fallbackAsset,
      fallbackAsset: fallbackAsset,
      color: _color(json['status_color'], 0xFF7AD95F),
    );
  }

  final String name;
  final int id;
  final int shopId;
  final String shop;
  final String area;
  final String shopImage;
  final String shopStatus;
  final String rating;
  final int age;
  final int height;
  final String style;
  final String bloodType;
  final String birthplace;
  final String hobby;
  final String attendanceFrequency;
  final String preferredMaleType;
  final String smokingDrinking;
  final String profile;
  final List<Map<String, dynamic>> reviews;
  final List<String> galleryImages;
  final List<String> tags;
  final bool isRecommended;
  final bool isNew;
  final bool isPopular;
  final String badge;
  final String button;
  final String asset;
  final String fallbackAsset;
  final int color;
}

class CampaignData {
  const CampaignData({
    required this.tag,
    required this.lead,
    required this.offer,
    required this.time,
    required this.asset,
    required this.shopName,
    required this.plan,
  });

  factory CampaignData.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final label = json['label'] as String? ?? '';
    final body = json['body'] as String? ?? '';
    final salePrice = json['sale_price'] as String? ?? '';
    final price = json['price'] as String? ?? '';
    final shopName = json['shop_name'] as String? ?? '';
    final plan = Map<String, dynamic>.from(json)
      ..['name'] = title
      ..['description'] = body;
    final image = _resolveImageUrl(
      json['image'] as String? ?? json['cover_asset'] as String? ?? '',
    );

    return CampaignData(
      tag: json['tag'] as String? ?? label,
      lead: json['lead'] as String? ?? shopName,
      offer:
          json['offer'] as String? ??
          (salePrice.isNotEmpty
              ? salePrice
              : price.isNotEmpty
              ? price
              : body),
      time: json['time'] as String? ?? title,
      asset: image.isNotEmpty
          ? image
          : 'assets/home/campaign-first-visit-v1.png',
      shopName: shopName,
      plan: plan,
    );
  }

  final String tag;
  final String lead;
  final String offer;
  final String time;
  final String asset;
  final String shopName;
  final Map<String, dynamic> plan;
}

class NewsData {
  const NewsData({
    required this.category,
    required this.title,
    required this.content,
    required this.date,
    required this.logo,
    required this.link,
  });

  factory NewsData.fromJson(Map<String, dynamic> json) {
    final logo = _resolveImageUrl(json['logo_image'] as String? ?? '');
    return NewsData(
      category: json['category'] as String? ?? 'NEWS',
      title: json['title'] as String? ?? json['content'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date:
          json['date'] as String? ??
          json['published_at'] as String? ??
          json['created_at'] as String? ??
          '',
      logo: logo,
      link: json['link'] as String? ?? '',
    );
  }

  final String category;
  final String title;
  final String content;
  final String date;
  final String logo;
  final String link;
}

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return [];
  final result = value.whereType<Map<String, dynamic>>().map(mapper).toList();
  return result;
}

List<String> _stringList(Object? value) {
  if (value is! List) return [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<ShopData> _shopList(Object? value) {
  if (value is! List) return [];

  final rows = value.whereType<Map<String, dynamic>>().toList();
  if (rows.isEmpty) return [];

  return [
    for (var index = 0; index < rows.length; index++)
      ShopData.fromJson(rows[index], index: index),
  ];
}

int _color(Object? value, int fallback) {
  if (value is! String) return fallback;
  final normalized = value.replaceFirst('#', '');
  return int.tryParse('FF$normalized', radix: 16) ?? fallback;
}

int _rankColor(int index) {
  return const [0xFFB88A43, 0xFFBFC2C6, 0xFF9B7148][index % 3];
}

String _resolveImageUrl(String value) {
  final image = value.trim();
  if (image.isEmpty) {
    return image;
  }

  final base = Uri.parse(AppConfig.apiBaseUrl);
  final uri = Uri.tryParse(image);
  if (uri != null && uri.hasScheme) {
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      return uri
          .replace(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : null,
          )
          .toString();
    }
    return image;
  }

  final path = image.startsWith('/') ? image : '/$image';
  return base.replace(path: path, query: '', fragment: '').toString();
}

const _defaultShopAssets = [
  'assets/home/shop-luxe-tokyo-cover-v1.png',
  'assets/home/shop-venus-cover-v1.png',
  'assets/home/shop-aile-cover-v1.png',
];

const _mockAreaOptions = [
  AreaData(id: 1, name: '北海道'),
  AreaData(id: 2, name: '青森県'),
  AreaData(id: 3, name: '岩手県'),
  AreaData(id: 4, name: '宮城県'),
  AreaData(id: 5, name: '秋田県'),
  AreaData(id: 6, name: '山形県'),
  AreaData(id: 7, name: '福島県'),
  AreaData(id: 8, name: '茨城県'),
  AreaData(id: 9, name: '栃木県'),
  AreaData(id: 10, name: '群馬県'),
  AreaData(id: 11, name: '埼玉県'),
  AreaData(id: 12, name: '千葉県'),
  AreaData(id: 13, name: '東京都'),
  AreaData(id: 14, name: '神奈川県'),
  AreaData(id: 15, name: '新潟県'),
  AreaData(id: 16, name: '富山県'),
  AreaData(id: 17, name: '石川県'),
  AreaData(id: 18, name: '福井県'),
  AreaData(id: 19, name: '山梨県'),
  AreaData(id: 20, name: '長野県'),
  AreaData(id: 21, name: '岐阜県'),
  AreaData(id: 22, name: '静岡県'),
  AreaData(id: 23, name: '愛知県'),
  AreaData(id: 24, name: '三重県'),
  AreaData(id: 25, name: '滋賀県'),
  AreaData(id: 26, name: '京都府'),
  AreaData(id: 27, name: '大阪府'),
  AreaData(id: 28, name: '兵庫県'),
  AreaData(id: 29, name: '奈良県'),
  AreaData(id: 30, name: '和歌山県'),
  AreaData(id: 31, name: '鳥取県'),
  AreaData(id: 32, name: '島根県'),
  AreaData(id: 33, name: '岡山県'),
  AreaData(id: 34, name: '広島県'),
  AreaData(id: 35, name: '山口県'),
  AreaData(id: 36, name: '徳島県'),
  AreaData(id: 37, name: '香川県'),
  AreaData(id: 38, name: '愛媛県'),
  AreaData(id: 39, name: '高知県'),
  AreaData(id: 40, name: '福岡県'),
  AreaData(id: 41, name: '佐賀県'),
  AreaData(id: 42, name: '長崎県'),
  AreaData(id: 43, name: '熊本県'),
  AreaData(id: 44, name: '大分県'),
  AreaData(id: 45, name: '宮崎県'),
  AreaData(id: 46, name: '鹿児島県'),
  AreaData(id: 47, name: '沖縄県'),
];
