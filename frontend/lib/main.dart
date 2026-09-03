import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/auth_api.dart';
import 'services/avatar_picker.dart';
import 'services/biometric_auth.dart';
import 'services/home_api.dart';
import 'services/order_api.dart';
import 'services/favorite_api.dart';
import 'services/payment_api.dart';
import 'services/coupon_api.dart';
import 'services/terms_api.dart';
import 'services/notice_api.dart';
import 'services/location_api.dart';
import 'services/support_api.dart';
import 'config/app_config.dart';
import 'widgets/footer_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  AppSession.restore(preferences);
  final biometric = BiometricAuthService();
  if (await biometric.isEnabled()) {
    AppSession.isAuthenticated = false;
    final token = await biometric.restoreToken();
    if (token != null && token.isNotEmpty) {
      await AppSession.authenticate(token);
    }
  }
  runApp(const CabakuraApp());
}

String _resolvePlanImageUrl(String value) {
  final image = value.trim();
  if (image.isEmpty) return image;
  final uri = Uri.tryParse(image);
  if (uri != null && uri.hasScheme) return image;
  final base = Uri.parse(AppConfig.apiBaseUrl);
  final path = image.startsWith('/') ? image : '/$image';
  return '${base.scheme}://${base.authority}$path';
}

final appNavigatorKey = GlobalKey<NavigatorState>();

class CabakuraApp extends StatefulWidget {
  const CabakuraApp({super.key});

  @override
  State<CabakuraApp> createState() => _CabakuraAppState();
}

class _CabakuraAppState extends State<CabakuraApp> {
  Timer? _sessionTimer;
  bool _handlingSessionExpiry = false;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkSession(),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkSession() async {
    if (!AppSession.isAuthenticated || _handlingSessionExpiry) return;
    try {
      await AuthApi().fetchProfile(token: AppSession.token);
    } on SessionExpiredException catch (error) {
      await _handleSessionExpiry(error.message);
    } catch (_) {
      // Network errors must not log the user out.
    }
  }

  Future<void> _handleSessionExpiry(String message) async {
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;
    await AppSession.clear();
    final navigator = appNavigatorKey.currentState;
    if (navigator == null || !navigator.mounted) {
      _handlingSessionExpiry = false;
      return;
    }
    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171513),
        title: const Text(
          'ログアウトのお知らせ',
          style: TextStyle(color: Color(0xFFF1D084)),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確認', style: TextStyle(color: Color(0xFFF1D084))),
          ),
        ],
      ),
    );
    if (navigator.mounted) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
    _handlingSessionExpiry = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Caba Night',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans JP',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD7B56D),
          brightness: Brightness.dark,
        ),
      ),
      initialRoute:
          Uri.base.path == '/login' ||
              Uri.base.queryParameters['page'] == 'login' ||
              Uri.base.fragment == '/login'
          ? '/login'
          : '/',
      routes: {
        '/': (_) => HomePage(api: HomeApi()),
        '/login': (_) => const LoginPage(),
      },
    );
  }
}

class AppSession {
  AppSession._();

  static const _tokenKey = 'cabago_auth_token';
  static const _profileKey = 'cabago_cached_profile';
  static String currentArea = '東京都';
  static SharedPreferences? _preferences;
  static bool isAuthenticated = false;
  static String token = '';
  static UserProfile? cachedProfile;
  static int supportUnreadCount = 0;
  static int noticeUnreadCount = 0;

  static void restore(SharedPreferences preferences) {
    _preferences = preferences;
    token = preferences.getString(_tokenKey) ?? '';
    isAuthenticated = token.isNotEmpty;
    final cached = preferences.getString(_profileKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        cachedProfile = UserProfile.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } catch (_) {
        cachedProfile = null;
      }
    }
  }

  static Future<void> authenticate(String value) async {
    token = value;
    isAuthenticated = value.isNotEmpty;
    await _preferences?.setString(_tokenKey, value);
  }

  static Future<void> clear() async {
    token = '';
    isAuthenticated = false;
    noticeUnreadCount = 0;
    await _preferences?.remove(_tokenKey);
    await _preferences?.remove(_profileKey);
    cachedProfile = null;
  }

  static Future<void> cacheProfile(UserProfile profile) async {
    cachedProfile = profile;
    await _preferences?.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}

void _openProtectedPage(BuildContext context, Widget page) {
  PageRouteBuilder<void> route() => PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => page,
  );

  if (AppSession.isAuthenticated) {
    Navigator.of(context).pushReplacement(route());
    return;
  }

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LoginPage(),
    ),
  );
}

Future<void> _openProtectedSubPage(BuildContext context, Widget page) {
  PageRouteBuilder<void> route() => PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => page,
  );

  if (AppSession.isAuthenticated) {
    return Navigator.of(context).push(route());
  }

  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LoginPage(),
    ),
  );
}

void _returnToPreviousOrLogin(BuildContext context, [Object? result]) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop(result);
    return;
  }
  navigator.pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LoginPage(),
    ),
  );
}

void _returnToPreviousOrHome(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
    ),
  );
}

void _openShopPage(BuildContext context, String area) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => ShopPage(api: HomeApi(), initialArea: area),
    ),
  );
}

void _openHomePage(BuildContext context) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
    ),
  );
}

void _handleDetailFooterNavigation(
  BuildContext context,
  int index,
  String area,
) {
  if (index == 0) {
    _openHomePage(context);
  } else if (index == 1) {
    _openShopPage(context, AppSession.currentArea);
  } else if (index == 2) {
    _openCastPage(context, AppSession.currentArea);
  } else if (index == 3) {
    _openOrderPage(context, area);
  } else if (index == 4) {
    _openMyPage(context, area);
  }
}

void _openShopDetail(BuildContext context, ShopData shop) {
  _openShopDetailAtTab(context, shop);
}

void _openShopDetailAtTab(
  BuildContext context,
  ShopData shop, [
  int initialTab = 0,
]) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) =>
          ShopDetailPage(shop: shop, initialTab: initialTab),
    ),
  );
}

void _openSearchResults(BuildContext context, String area, String keyword) {
  final normalizedKeyword = keyword.trim();
  if (normalizedKeyword.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => SearchResultsPage(
        api: HomeApi(),
        initialArea: area,
        initialKeyword: normalizedKeyword,
      ),
    ),
  );
}

void _openCastPage(BuildContext context, String area) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => CastPage(api: HomeApi(), initialArea: area),
    ),
  );
}

void _openCastDetail(BuildContext context, CastData cast) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => CastDetailPage(cast: cast),
    ),
  );
}

void _openCastShopPrice(BuildContext context, CastData cast) {
  if (cast.shopId <= 0) return;
  final shop = ShopData(
    id: cast.shopId,
    name: cast.shop,
    area: cast.area,
    description: '',
    address: '',
    station: '',
    isRecommended: false,
    businessStatus: cast.shopStatus == '営業中' ? '営業中' : '休み',
    businessHours: '',
    bookingEnabled: false,
    shopImages: cast.shopImage.isEmpty ? const [] : [cast.shopImage],
    packageSets: const [],
    casts: const [],
    reviews: const [],
    price: '',
    score: '4.5',
    count: '',
    tags: const [],
    asset: cast.shopImage.isNotEmpty
        ? cast.shopImage
        : 'assets/home/shop-luxe-v1.png',
    fallbackAsset: 'assets/home/shop-luxe-v1.png',
    rank: '',
    ribbonColor: 0xFFD7A952,
    isSearchFallback: false,
  );
  _openShopDetailAtTab(context, shop, 1);
}

void _openNewsPage(BuildContext context, String area) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => NewsPage(api: HomeApi(), initialArea: area),
    ),
  );
}

void _openNoticePage(BuildContext context) {
  _openProtectedPage(context, const NoticePage());
}

class NoticeBellButton extends StatefulWidget {
  const NoticeBellButton({super.key, this.iconSize = 24});

  final double iconSize;

  @override
  State<NoticeBellButton> createState() => _NoticeBellButtonState();
}

class _NoticeBellButtonState extends State<NoticeBellButton> {
  Timer? _refreshTimer;
  int _unreadCount = AppSession.noticeUnreadCount;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadUnreadCount(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (!AppSession.isAuthenticated || AppSession.token.isEmpty) {
      if (mounted) setState(() => _unreadCount = 0);
      return;
    }
    try {
      final count = await NoticeApi().fetchUnreadCount(token: AppSession.token);
      AppSession.noticeUnreadCount = count;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Keep the last known state when the API is temporarily unavailable.
    }
  }

  Future<void> _openNotices() async {
    if (!AppSession.isAuthenticated) {
      _openNoticePage(context);
      return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const NoticePage(),
      ),
    );
    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'お知らせ',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: _openNotices,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: const Color(0xFFD7B56D),
            size: widget.iconSize,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: -1,
              top: -2,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF554F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _openNewsDetail(BuildContext context, NewsData news) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => NewsDetailPage(news: news),
    ),
  );
}

void _openOrderPage(BuildContext context, String area) {
  _openProtectedPage(context, OrderPage(api: HomeApi(), initialArea: area));
}

void _openMyPage(BuildContext context, String area) {
  _openProtectedPage(context, MyPage(api: HomeApi(), initialArea: area));
}

void _openPaymentMethodsPage(BuildContext context) {
  _openProtectedSubPage(context, const PaymentMethodsPage());
}

void _openPaymentCardEditPage(BuildContext context) {
  _openProtectedSubPage(context, const PaymentCardEditPage());
}

void _openIdentityVerificationPage(BuildContext context) {
  _openProtectedSubPage(context, const IdentityVerificationPage());
}

void _openCouponPage(BuildContext context) {
  _openProtectedSubPage(context, const CouponPage());
}

void _openTermsPage(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const TermsPage(),
    ),
  );
}

Future<void> _openMemberEditPage(
  BuildContext context,
  UserProfile? profile,
) async {
  await _openProtectedSubPage(context, MemberEditPage(profile: profile));
}

void _openPhoneVerificationPage(BuildContext context, String mobile) {
  _openProtectedSubPage(context, PhoneVerificationPage(mobile: mobile));
}

void _openNotificationSettingsPage(BuildContext context) {
  _openProtectedSubPage(context, const NotificationSettingsPage());
}

void _openSettingsPage(BuildContext context) {
  _openProtectedSubPage(context, const SettingsPage());
}

void _openHelpSupportPage(BuildContext context) {
  _openProtectedSubPage(context, const HelpSupportPage());
}

void _openFavoriteShopsPage(BuildContext context) {
  _openProtectedSubPage(context, const FavoriteShopsPage());
}

void _openFavoriteCastsPage(BuildContext context) {
  _openProtectedSubPage(context, const FavoriteCastsPage());
}

class FavoriteCastsPage extends StatefulWidget {
  const FavoriteCastsPage({super.key});

  @override
  State<FavoriteCastsPage> createState() => _FavoriteCastsPageState();
}

class _FavoriteCastsPageState extends State<FavoriteCastsPage> {
  late final Future<List<CastData>> _castsFuture = _loadCasts();

  Future<List<CastData>> _loadCasts() async {
    final rows = await FavoriteApi().fetchCasts(token: AppSession.token);
    return rows.map(CastData.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      bottom: false,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Text(
                        'お気に入りキャスト',
                        style: TextStyle(
                          color: Color(0xFFF0C96D),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 19,
                            color: Color(0xFFE2B85F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 90),
                sliver: FutureBuilder<List<CastData>>(
                  future: _castsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    final casts = snapshot.data ?? const <CastData>[];
                    if (casts.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: Text(
                              'お気に入りキャストはありません',
                              style: TextStyle(color: Color(0xFF9B9B9B)),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CastListCard(
                            cast: casts[index],
                            onTap: () => _openCastDetail(context, casts[index]),
                            onBook: () =>
                                _openCastShopPrice(context, casts[index]),
                          ),
                        ),
                        childCount: casts.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class FavoriteShopsPage extends StatefulWidget {
  const FavoriteShopsPage({super.key});

  @override
  State<FavoriteShopsPage> createState() => _FavoriteShopsPageState();
}

class _FavoriteShopsPageState extends State<FavoriteShopsPage> {
  late final Future<List<ShopData>> _shopsFuture = _loadShops();

  Future<List<ShopData>> _loadShops() async {
    final rows = await FavoriteApi().fetchShops(token: AppSession.token);
    return [
      for (var index = 0; index < rows.length; index++)
        ShopData.fromJson(rows[index], index: index),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text(
                          'お気に入り店舗',
                          style: TextStyle(
                            color: Color(0xFFF0C96D),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 19,
                              color: Color(0xFFE2B85F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
                  sliver: FutureBuilder<List<ShopData>>(
                    future: _shopsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }
                      final shops = snapshot.data ?? const <ShopData>[];
                      if (shops.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(
                              child: Text(
                                'お気に入り店舗はありません',
                                style: TextStyle(color: Color(0xFF9B9B9B)),
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ShopListCard(
                              shop: shops[index],
                              onTap: () =>
                                  _openShopDetail(context, shops[index]),
                              onBook: () => _openShopDetailAtTab(
                                context,
                                shops[index],
                                1,
                              ),
                            ),
                          ),
                          childCount: shops.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FooterNavigation(
                activeIndex: 4,
                onItemTap: (index) => _handleDetailFooterNavigation(
                  context,
                  index,
                  AppSession.currentArea,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _phoneController = TextEditingController();
  late final TextEditingController _passwordController =
      TextEditingController();
  String _countryCode = '+81';
  bool _isSubmitting = false;
  late final AuthApi _authApi = AuthApi();

  bool get _canLogin =>
      _phoneController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showDevelopmentMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _login() async {
    if (!_canLogin || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final token = await _authApi.login(
        account: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      await AppSession.authenticate(token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      _showDevelopmentMessage(message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => ForgotPasswordPage(
          initialMobile: _phoneController.text.trim(),
          allowEmail: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 20, 28),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '戻る',
                  onPressed: _isSubmitting
                      ? null
                      : () => _returnToPreviousOrHome(context),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFFF1D084),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'ログイン',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Caba Nightをもっと便利にご利用いただくためにログインしてください',
                style: TextStyle(fontSize: 11, color: Color(0xFFA6A6AA)),
              ),
              const SizedBox(height: 20),
              _LoginPhoneField(
                controller: _phoneController,
                countryCode: _countryCode,
                onCountryChanged: (value) {
                  setState(() => _countryCode = value);
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _LoginPasswordField(
                controller: _passwordController,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _openForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    foregroundColor: const Color(0xFFD7B56D),
                  ),
                  child: const Text(
                    'パスワードをお忘れの方',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _LoginPrimaryButton(
                enabled: _canLogin && !_isSubmitting,
                label: 'ログイン',
                onTap: _canLogin && !_isSubmitting ? _login : null,
              ),
              const SizedBox(height: 10),
              _LoginSecondaryButton(
                label: '認証コードでログイン',
                icon: Icons.sms_outlined,
                onTap: () => _showDevelopmentMessage('認証コードログインは準備中です'),
              ),
              const SizedBox(height: 18),
              const _LoginDivider(label: 'その他の認証方法'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SocialLoginButton(
                    label: 'Apple',
                    icon: Icons.apple,
                    onTap: () => _showDevelopmentMessage('Appleログインは準備中です'),
                  ),
                  const SizedBox(width: 8),
                  _SocialLoginButton(
                    label: 'Google',
                    icon: Icons.language,
                    onTap: () => _showDevelopmentMessage('Googleログインは準備中です'),
                  ),
                  const SizedBox(width: 8),
                  _SocialLoginButton(
                    label: 'LINE',
                    icon: Icons.chat_bubble_outline,
                    onTap: () => _showDevelopmentMessage('LINEログインは準備中です'),
                  ),
                  const SizedBox(width: 8),
                  _SocialLoginButton(
                    label: 'Gmail',
                    icon: Icons.mail_outline,
                    onTap: () => _showDevelopmentMessage('Gmailログインは準備中です'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _LoginSecondaryButton(
                label: '新規登録',
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => const RegisterPage(),
                    ),
                  );
                },
              ),
            ],
          );

          return Container(
            color: const Color(0xFF050505),
            child: constraints.maxWidth >= 720
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: content,
                    ),
                  )
                : SafeArea(child: content),
          );
        },
      ),
    );
  }
}

class _LoginPhoneField extends StatelessWidget {
  const _LoginPhoneField({
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        border: Border.all(color: const Color(0xFF4A4030)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: countryCode,
                isExpanded: true,
                dropdownColor: const Color(0xFF24221E),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF77777C),
                ),
                padding: const EdgeInsets.only(left: 10),
                items: const [
                  DropdownMenuItem(value: '+81', child: Text('+81')),
                  DropdownMenuItem(value: '+86', child: Text('+86')),
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                ],
                onChanged: (value) {
                  if (value != null) onCountryChanged(value);
                },
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF1D084),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: const Color(0xFF4A4030)),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: SizedBox(
                  height: 26,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    onChanged: onChanged,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '携帯番号',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF77777C),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.only(left: 12, right: 4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPasswordField extends StatefulWidget {
  const _LoginPasswordField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_LoginPasswordField> createState() => _LoginPasswordFieldState();
}

class _LoginPasswordFieldState extends State<_LoginPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        border: Border.all(color: const Color(0xFF4A4030)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 2),
          child: SizedBox(
            height: 26,
            child: TextField(
              controller: widget.controller,
              obscureText: _obscure,
              onChanged: widget.onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'パスワード',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF77777C),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  maxWidth: 40,
                  minHeight: 26,
                  maxHeight: 26,
                ),
                suffixIcon: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 26,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 17,
                    color: const Color(0xFF77777C),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  const _LoginPrimaryButton({
    required this.enabled,
    required this.label,
    this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Material(
        color: enabled ? const Color(0xFFC3944A) : const Color(0xFF3A3937),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? const Color(0xFF201A10)
                    : const Color(0xFF858589),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginSecondaryButton extends StatelessWidget {
  const _LoginSecondaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, size: 15, color: const Color(0xFFF1D084)),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF1D084),
          side: const BorderSide(color: Color(0xFF8A6B37)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _LoginDivider extends StatelessWidget {
  const _LoginDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFF38342D), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF77777C)),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFF38342D), height: 1)),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 54,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: const Color(0xFFE5E5E7),
            side: const BorderSide(color: Color(0xFF38342D)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(height: 3),
              Text(label, style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalityController = TextEditingController(text: '日本');
  final _postalController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingController = TextEditingController();
  final _authApi = AuthApi();
  var _step = 0;
  var _codeSent = false;
  var _agreed = false;
  var _isSubmitting = false;
  var _isSendingCode = false;

  bool get _canContinue =>
      _phoneController.text.trim().isNotEmpty &&
      _codeController.text.trim() == '123456' &&
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _passwordConfirmController.text &&
      _agreed;

  @override
  void dispose() {
    for (final controller in [
      _phoneController,
      _codeController,
      _passwordController,
      _passwordConfirmController,
      _nicknameController,
      _nameController,
      _emailController,
      _nationalityController,
      _postalController,
      _addressController,
      _buildingController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _sendCode() async {
    if (_isSendingCode) return;
    final mobile = _phoneController.text.trim();
    if (mobile.isEmpty) {
      _showMessage('電話番号を入力してください');
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      await _authApi.checkRegisterMobile(mobile: mobile);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showMessage('認証コードを送信しました（開発環境）');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  void _continue() {
    if (!_canContinue) {
      _showMessage('入力内容を確認してください');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _completeRegistration() async {
    if (_nicknameController.text.trim().isEmpty || _isSubmitting) {
      _showMessage('ニックネームを入力してください');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _authApi.register(
        account: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      final token = await _authApi.login(
        account: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      await AppSession.authenticate(token);
      await _authApi.saveMemberProfile(
        nickname: _nicknameController.text.trim(),
        realName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        nationality: _nationalityController.text.trim(),
        postalCode: _postalController.text.trim(),
        address: _addressController.text.trim(),
        buildingName: _buildingController.text.trim(),
        token: token,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (_step == 0) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _step = 0);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFFD7B56D),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 8),
            Text(
              _step == 0 ? '新規登録' : 'プロフィール登録',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _step == 0 ? '電話番号を認証してCaba Nightをはじめましょう' : '会員情報を入力して登録を完了してください',
          style: const TextStyle(fontSize: 11, color: Color(0xFFA6A6AA)),
        ),
        const SizedBox(height: 22),
        if (_step == 0) _buildPhoneStep() else _buildProfileStep(),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: const Color(0xFF050505),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 720
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: content,
                    ),
                  )
                : content,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RegisterLabel(label: '電話番号'),
        _LoginPhoneField(
          controller: _phoneController,
          countryCode: '+81',
          onCountryChanged: (_) {},
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        const _RegisterLabel(label: '認証コード'),
        Row(
          children: [
            Expanded(
              child: _RegisterInput(
                controller: _codeController,
                hint: '認証コードを入力',
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _isSendingCode ? null : _sendCode,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF1D084),
                  side: const BorderSide(color: Color(0xFF8A6B37)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  _isSendingCode ? '確認中' : (_codeSent ? '再送信' : 'コード送信'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _RegisterLabel(label: 'パスワード'),
        _LoginPasswordField(
          controller: _passwordController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        const _RegisterLabel(label: 'パスワード（確認）'),
        _RegisterInput(
          controller: _passwordConfirmController,
          hint: 'パスワードを再入力',
          obscureText: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _agreed,
          onChanged: (value) => setState(() => _agreed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: const Color(0xFFC3944A),
          title: const Text(
            '利用規約とプライバシーポリシーに同意する',
            style: TextStyle(fontSize: 11, color: Color(0xFFBDBDC2)),
          ),
        ),
        const SizedBox(height: 12),
        _LoginPrimaryButton(
          enabled: _canContinue,
          label: '次へ',
          onTap: _canContinue ? _continue : null,
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RegisterLabel(label: 'ニックネーム'),
        _RegisterInput(controller: _nicknameController, hint: 'ニックネーム *'),
        const SizedBox(height: 10),
        const _RegisterLabel(label: '氏名'),
        _RegisterInput(controller: _nameController, hint: '氏名'),
        const SizedBox(height: 10),
        const _RegisterLabel(label: 'メールアドレス'),
        _RegisterInput(
          controller: _emailController,
          hint: 'メールアドレス',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        const _RegisterLabel(label: '国籍'),
        _RegisterSelect(
          value: _nationalityController.text,
          options: const ['日本', '中国', '韓国', 'その他'],
          onChanged: (value) {
            if (value != null) {
              _nationalityController.text = value;
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 10),
        const _RegisterLabel(label: '郵便番号'),
        _RegisterInput(
          controller: _postalController,
          hint: '郵便番号',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        const _RegisterLabel(label: '住所'),
        _RegisterInput(controller: _addressController, hint: '住所'),
        const SizedBox(height: 10),
        const _RegisterLabel(label: '建物名・部屋番号'),
        _RegisterInput(controller: _buildingController, hint: '建物名・部屋番号'),
        const SizedBox(height: 20),
        _LoginPrimaryButton(
          enabled: !_isSubmitting,
          label: _isSubmitting ? '登録中...' : '登録を完了',
          onTap: _isSubmitting ? null : _completeRegistration,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            '登録完了後、自動的にログインします',
            style: TextStyle(fontSize: 10, color: Color(0xFF77777C)),
          ),
        ),
      ],
    );
  }
}

class _RegisterLabel extends StatelessWidget {
  const _RegisterLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD7B56D),
        ),
      ),
    );
  }
}

class _RegisterInput extends StatelessWidget {
  const _RegisterInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        border: Border.all(color: const Color(0xFF4A4030)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 2),
          child: SizedBox(
            height: 26,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF77777C),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterSelect extends StatelessWidget {
  const _RegisterSelect({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        border: Border.all(color: const Color(0xFF4A4030)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF24221E),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF77777C),
          ),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});

  final HomeApi api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedArea = AppSession.currentArea;
  String _keyword = '';
  late final TextEditingController _searchController = TextEditingController();
  late Future<HomeViewData> _homeData = widget.api.fetchHome(
    area: _selectedArea,
  );
  bool _manualAreaSelected = false;

  @override
  void initState() {
    super.initState();
    _detectCurrentArea();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectArea(String area) {
    if (area == _selectedArea) {
      return;
    }

    setState(() {
      _manualAreaSelected = true;
      _selectedArea = area;
      AppSession.currentArea = area;
      _homeData = widget.api.fetchHome(area: area, keyword: _keyword);
    });
  }

  Future<void> _detectCurrentArea() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final area = await LocationApi().resolveArea(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || _manualAreaSelected || area == null || area.isEmpty) {
        return;
      }
      if (area == _selectedArea) return;
      setState(() {
        _selectedArea = area;
        AppSession.currentArea = area;
        _homeData = widget.api.fetchHome(area: area, keyword: _keyword);
      });
    } catch (_) {
      // Location is optional; keep the default/manual area when unavailable.
    }
  }

  void _search(String keyword) {
    final nextKeyword = keyword.trim();
    if (nextKeyword.isEmpty) return;
    _openSearchResults(context, _selectedArea, nextKeyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<HomeViewData>(
        future: _homeData,
        builder: (context, snapshot) {
          return ResponsiveHome(
            data:
                snapshot.data ??
                HomeViewData.empty(selectedArea: _selectedArea),
            onAreaSelected: _selectArea,
            searchController: _searchController,
            onSearch: _search,
          );
        },
      ),
    );
  }
}

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({
    super.key,
    required this.api,
    required this.initialArea,
    required this.initialKeyword,
  });

  final HomeApi api;
  final String initialArea;
  final String initialKeyword;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _searchController = TextEditingController(
    text: widget.initialKeyword,
  );
  late String _keyword = widget.initialKeyword;
  late Future<HomeViewData> _future = widget.api.fetchHome(
    area: widget.initialArea,
    keyword: widget.initialKeyword,
    includeAreaTree: false,
    strictSearch: true,
  );
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    final nextKeyword = value.trim();
    if (nextKeyword.isEmpty || nextKeyword == _keyword) return;
    setState(() {
      _keyword = nextKeyword;
      _searchController.text = nextKeyword;
      _future = widget.api.fetchHome(
        area: widget.initialArea,
        keyword: nextKeyword,
        includeAreaTree: false,
        strictSearch: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '検索結果',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: NoticeBellButton(iconSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AiSearchBar(
                controller: _searchController,
                onSearch: _search,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFFD7B56D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '検索範囲：${widget.initialArea == '全エリア' ? '全エリア' : widget.initialArea}',
                    style: const TextStyle(
                      color: Color(0xFFAAA7A1),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SearchTypeTabs(
              selectedIndex: _selectedTab,
              onChanged: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<HomeViewData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF1D084),
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (data == null) {
                    return const _SearchEmptyState();
                  }
                  return _SearchResultsBody(
                    data: data,
                    selectedTab: _selectedTab,
                  );
                },
              ),
            ),
            FooterNavigation(
              activeIndex: 0,
              onItemTap: (index) => HomeScreen._handleFooterTap(
                context,
                index,
                widget.initialArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchTypeTabs extends StatelessWidget {
  const _SearchTypeTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['すべて', '店舗', 'キャスト', 'セットプラン'];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: index == 3 ? 112 : 78,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selectedIndex == index
                  ? const Color(0xFFE0B85F)
                  : const Color(0xFF151514),
              border: Border.all(
                color: selectedIndex == index
                    ? const Color(0xFFE0B85F)
                    : const Color(0xFF4B443A),
              ),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                color: selectedIndex == index
                    ? const Color(0xFF15120D)
                    : const Color(0xFFD0CDD0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultsBody extends StatelessWidget {
  const _SearchResultsBody({required this.data, required this.selectedTab});

  final HomeViewData data;
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    if (selectedTab == 0 || selectedTab == 1) {
      if (data.shops.isNotEmpty) {
        sections.add(_SearchShopResults(shops: data.shops));
      }
    }
    if (selectedTab == 0 || selectedTab == 2) {
      if (data.casts.isNotEmpty) {
        sections.add(_SearchCastResults(casts: data.casts));
      }
    }
    if (selectedTab == 0 || selectedTab == 3) {
      if (data.campaigns.isNotEmpty) {
        sections.add(_SearchPlanResults(plans: data.campaigns));
      }
    }
    if (sections.isEmpty) return const _SearchEmptyState();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (_, index) => sections[index],
    );
  }
}

class _SearchShopResults extends StatelessWidget {
  const _SearchShopResults({required this.shops});
  final List<ShopData> shops;

  @override
  Widget build(BuildContext context) => _SearchSection(
    title: '店舗',
    count: shops.length,
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final shop in shops)
          ShopCard(
            shop: shop,
            onTap: () => _openShopDetail(context, shop),
            onBook: () => _openShopDetailAtTab(context, shop, 1),
          ),
      ],
    ),
  );
}

class _SearchCastResults extends StatelessWidget {
  const _SearchCastResults({required this.casts});
  final List<CastData> casts;

  @override
  Widget build(BuildContext context) => _SearchSection(
    title: 'キャスト',
    count: casts.length,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final cast in casts)
          CastCard(cast: cast, onTap: () => _openCastDetail(context, cast)),
      ],
    ),
  );
}

class _SearchPlanResults extends StatelessWidget {
  const _SearchPlanResults({required this.plans});
  final List<CampaignData> plans;

  @override
  Widget build(BuildContext context) => _SearchSection(
    title: 'セットプラン',
    count: plans.length,
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final plan in plans) CampaignCard(campaign: plan)],
    ),
  );
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({
    required this.title,
    required this.count,
    required this.child,
  });
  final String title;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(title: '$title  $count件', showSeeAll: false),
      const SizedBox(height: 12),
      child,
    ],
  );
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, color: Color(0xFFD7B56D), size: 36),
        SizedBox(height: 12),
        Text(
          '検索結果はありません',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '別のキーワードでお試しください',
          style: TextStyle(color: Color(0xFFAAA7A1), fontSize: 12),
        ),
      ],
    ),
  );
}

class ResponsiveHome extends StatelessWidget {
  const ResponsiveHome({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return DesktopHomeScreen(
            data: data,
            onAreaSelected: onAreaSelected,
            searchController: searchController,
            onSearch: onSearch,
          );
        }

        return SafeArea(
          child: HomeScreen(
            data: data,
            onAreaSelected: onAreaSelected,
            searchController: searchController,
            onSearch: onSearch,
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: TopHeader(
              area: data.area,
              areaOptions: data.areaOptions,
              onAreaSelected: onAreaSelected,
              searchController: searchController,
              onSearch: onSearch,
            ),
          ),
          Positioned.fill(
            top: 116,
            bottom: 72,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 7),
                PopularShopsSection(
                  shops: data.shops,
                  onSeeAll: () => _openShopPage(context, data.area),
                  onShopTap: (shop) => _openShopDetail(context, shop),
                  onBook: (shop) => _openShopDetailAtTab(context, shop, 1),
                ),
                const SizedBox(height: 17),
                PopularCastSection(
                  casts: data.casts,
                  onSeeAll: () => _openCastPage(context, data.area),
                ),
                const SizedBox(height: 18),
                CampaignSection(campaigns: data.campaigns),
                const SizedBox(height: 18),
                NewsSection(
                  news: data.news,
                  onSeeAll: () => _openNewsPage(context, data.area),
                  onNewsTap: (news) => _openNewsDetail(context, news),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              onItemTap: (index) => _handleFooterTap(context, index, data.area),
            ),
          ),
        ],
      ),
    );
  }

  static void _handleFooterTap(BuildContext context, int index, String area) {
    if (index == 1) {
      _openShopPage(context, area);
    } else if (index == 2) {
      _openCastPage(context, area);
    } else if (index == 3) {
      _openOrderPage(context, area);
    } else if (index == 4) {
      _openMyPage(context, area);
    }
  }
}

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DesktopHeader(
                    area: data.area,
                    areaOptions: data.areaOptions,
                    onAreaSelected: onAreaSelected,
                    searchController: searchController,
                    onSearch: onSearch,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 22, 28, 40),
                        child: Column(
                          children: [
                            DesktopRow(
                              child: PopularShopsSection(
                                shops: data.shops,
                                onSeeAll: () =>
                                    _openShopPage(context, data.area),
                                onShopTap: (shop) =>
                                    _openShopDetail(context, shop),
                                onBook: (shop) =>
                                    _openShopDetailAtTab(context, shop, 1),
                              ),
                            ),
                            const SizedBox(height: 24),
                            DesktopRow(
                              child: PopularCastSection(
                                casts: data.casts,
                                onSeeAll: () =>
                                    _openCastPage(context, data.area),
                              ),
                            ),
                            const SizedBox(height: 24),
                            DesktopRow(
                              child: CampaignSection(campaigns: data.campaigns),
                            ),
                            const SizedBox(height: 24),
                            DesktopRow(
                              child: NewsSection(
                                news: data.news,
                                onSeeAll: () =>
                                    _openNewsPage(context, data.area),
                                onNewsTap: (news) =>
                                    _openNewsDetail(context, news),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoticePage extends StatefulWidget {
  const NoticePage({super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  late Future<List<NoticeItem>> _future = NoticeApi().fetchNotices(
    token: AppSession.token,
  );

  @override
  void initState() {
    super.initState();
    NoticeApi().readAll(token: AppSession.token).then((_) {
      AppSession.noticeUnreadCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'お知らせ',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        _openMyPage(context, AppSession.currentArea),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<NoticeItem>>(
              future: _future,
              builder: (context, snapshot) {
                final notices = snapshot.data ?? const <NoticeItem>[];
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF1D084)),
                  );
                if (notices.isEmpty)
                  return const Center(
                    child: Text(
                      'お知らせはありません',
                      style: TextStyle(color: Color(0xFFAAA39A), fontSize: 14),
                    ),
                  );
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: notices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = notices[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111110),
                        border: Border.all(
                          color: item.read
                              ? const Color(0xFF3B3427)
                              : const Color(0xFFB9853E),
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Color(0xFFF1D084),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                item.createdAt,
                                style: const TextStyle(
                                  color: Color(0xFFAAA39A),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) {
              if (index != 4)
                _handleDetailFooterNavigation(
                  context,
                  index,
                  AppSession.currentArea,
                );
            },
          ),
        ],
      ),
    ),
  );
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, required this.api, this.initialArea = '東京都'});

  final HomeApi api;
  final String initialArea;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late String _selectedArea = widget.initialArea;
  String _keyword = '';
  late final TextEditingController _searchController = TextEditingController();
  late Future<HomeViewData> _newsData = widget.api.fetchHome(
    area: widget.initialArea,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectArea(String area) {
    if (area == _selectedArea) return;
    setState(() {
      _selectedArea = area;
      _newsData = widget.api.fetchHome(area: area, keyword: _keyword);
    });
  }

  void _search(String keyword) {
    final nextKeyword = keyword.trim();
    if (nextKeyword == _keyword) return;
    setState(() {
      _keyword = nextKeyword;
      _newsData = widget.api.fetchHome(area: _selectedArea, keyword: _keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<HomeViewData>(
        future: _newsData,
        builder: (context, snapshot) {
          return ResponsiveNewsScreen(
            data:
                snapshot.data ??
                HomeViewData.empty(selectedArea: _selectedArea),
            onAreaSelected: _selectArea,
            searchController: _searchController,
            onSearch: _search,
          );
        },
      ),
    );
  }
}

class ResponsiveNewsScreen extends StatelessWidget {
  const ResponsiveNewsScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= 720
            ? NewsDesktopScreen(
                data: data,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
              )
            : NewsMobileScreen(
                data: data,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
              );
        return constraints.maxWidth >= 720 ? content : SafeArea(child: content);
      },
    );
  }
}

class NewsMobileScreen extends StatelessWidget {
  const NewsMobileScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _newsHeader(context, compact: true),
          ),
          Positioned.fill(
            top: 70,
            bottom: 72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              children: [
                const SectionHeader(title: 'NEWS', showSeeAll: false),
                const SizedBox(height: 12),
                NewsResultBar(count: data.news.length),
                const SizedBox(height: 10),
                NewsListBody(
                  news: data.news,
                  onNewsTap: (news) => _openNewsDetail(context, news),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              onItemTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                    ),
                  );
                } else if (index == 1) {
                  _openShopPage(context, data.area);
                } else if (index == 2) {
                  _openCastPage(context, data.area);
                } else if (index == 3) {
                  _openOrderPage(context, data.area);
                } else if (index == 4) {
                  _openMyPage(context, data.area);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewsDesktopScreen extends StatelessWidget {
  const NewsDesktopScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _newsHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: 'NEWS',
                              showSeeAll: false,
                            ),
                            const SizedBox(height: 14),
                            NewsResultBar(count: data.news.length),
                            const SizedBox(height: 14),
                            NewsListBody(
                              news: data.news,
                              onNewsTap: (news) =>
                                  _openNewsDetail(context, news),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _newsHeader(BuildContext context, {bool compact = false}) {
  return SizedBox(
    height: compact ? 62 : 70,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Text(
          'NEWS',
          style: TextStyle(
            color: Color(0xFFF1D084),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: '戻る',
            onPressed: () => _openHomePage(context),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFF1D084),
              size: 30,
            ),
          ),
        ),
      ],
    ),
  );
}

class NewsResultBar extends StatelessWidget {
  const NewsResultBar({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count件',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC7C7CA),
          ),
        ),
        const Spacer(),
        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFD7B56D)),
        const SizedBox(width: 4),
        const Text(
          '最新順',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD7B56D),
          ),
        ),
      ],
    );
  }
}

class NewsListBody extends StatelessWidget {
  const NewsListBody({super.key, required this.news, this.onNewsTap});

  final List<NewsData> news;
  final ValueChanged<NewsData>? onNewsTap;

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(
          child: Text(
            'ニュースはありません',
            style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9F)),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in news) ...[
          NewsCard(news: item, onTap: () => onNewsTap?.call(item)),
          if (item != news.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key, required this.news});

  final NewsData news;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFFF1D084),
                tooltip: '戻る',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              news.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              news.date,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9B9B9F)),
            ),
            const SizedBox(height: 24),
            Text(
              news.content.isNotEmpty ? news.content : news.title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFD7D7DA),
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.api, this.initialArea = '東京都'});

  final HomeApi api;
  final String initialArea;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late String _selectedArea = widget.initialArea;
  String _keyword = '';
  int _selectedTab = 0;
  late final TextEditingController _searchController = TextEditingController();
  late Future<HomeViewData> _pageData = widget.api.fetchHome(
    area: widget.initialArea,
  );
  final Future<List<Map<String, dynamic>>> _orders = OrderApi().fetchMyOrders(
    token: AppSession.token,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectArea(String area) {
    if (area == _selectedArea) return;
    setState(() {
      _selectedArea = area;
      _pageData = widget.api.fetchHome(area: area, keyword: _keyword);
    });
  }

  void _search(String keyword) {
    final nextKeyword = keyword.trim();
    if (nextKeyword == _keyword) return;
    setState(() {
      _keyword = nextKeyword;
      _pageData = widget.api.fetchHome(area: _selectedArea, keyword: _keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<HomeViewData>(
        future: _pageData,
        builder: (context, snapshot) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _orders,
            builder: (context, ordersSnapshot) {
              return ResponsiveOrderScreen(
                data:
                    snapshot.data ??
                    HomeViewData.empty(selectedArea: _selectedArea),
                orders: ordersSnapshot.data ?? const [],
                selectedTab: _selectedTab,
                onTabChanged: (tab) => setState(() => _selectedTab = tab),
                onAreaSelected: _selectArea,
                searchController: _searchController,
                onSearch: _search,
              );
            },
          );
        },
      ),
    );
  }
}

class ResponsiveOrderScreen extends StatelessWidget {
  const ResponsiveOrderScreen({
    super.key,
    required this.data,
    required this.orders,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final List<Map<String, dynamic>> orders;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= 720
            ? OrderDesktopScreen(
                data: data,
                orders: orders,
                selectedTab: selectedTab,
                onTabChanged: onTabChanged,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
              )
            : OrderMobileScreen(
                data: data,
                orders: orders,
                selectedTab: selectedTab,
                onTabChanged: onTabChanged,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
              );
        return constraints.maxWidth >= 720 ? content : SafeArea(child: content);
      },
    );
  }
}

class OrderMobileScreen extends StatelessWidget {
  const OrderMobileScreen({
    super.key,
    required this.data,
    required this.orders,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final List<Map<String, dynamic>> orders;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: TopHeader(
              area: data.area,
              areaOptions: data.areaOptions,
              onAreaSelected: onAreaSelected,
              searchController: searchController,
              onSearch: onSearch,
              showSearch: false,
            ),
          ),
          Positioned.fill(
            top: 76,
            bottom: 72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              children: [
                const SectionHeader(title: 'オーダー', showSeeAll: false),
                const SizedBox(height: 16),
                OrderTabBar(selectedTab: selectedTab, onChanged: onTabChanged),
                const SizedBox(height: 18),
                OrderContent(orders: orders, area: data.area, tab: selectedTab),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              activeIndex: 3,
              onItemTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                    ),
                  );
                } else if (index == 1) {
                  _openShopPage(context, data.area);
                } else if (index == 2) {
                  _openCastPage(context, data.area);
                } else if (index == 3) {
                  _openOrderPage(context, data.area);
                } else if (index == 4) {
                  _openMyPage(context, data.area);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderDesktopScreen extends StatelessWidget {
  const OrderDesktopScreen({
    super.key,
    required this.data,
    required this.orders,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final HomeViewData data;
  final List<Map<String, dynamic>> orders;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          SafeArea(
            child: TopHeader(
              area: data.area,
              areaOptions: data.areaOptions,
              onAreaSelected: onAreaSelected,
              searchController: searchController,
              onSearch: onSearch,
              showSearch: false,
            ),
          ),
          Positioned.fill(
            top: 76,
            bottom: 72,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    const SectionHeader(title: 'オーダー', showSeeAll: false),
                    const SizedBox(height: 18),
                    OrderTabBar(
                      selectedTab: selectedTab,
                      onChanged: onTabChanged,
                    ),
                    const SizedBox(height: 22),
                    OrderContent(
                      orders: orders,
                      area: data.area,
                      tab: selectedTab,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              activeIndex: 3,
              onItemTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                    ),
                  );
                } else if (index == 1) {
                  _openShopPage(context, data.area);
                } else if (index == 2) {
                  _openCastPage(context, data.area);
                } else if (index == 3) {
                  _openOrderPage(context, data.area);
                } else if (index == 4) {
                  _openMyPage(context, data.area);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OrderTabBar extends StatelessWidget {
  const OrderTabBar({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['すべて', '予約中', '未払い', '支払済み', 'キャンセル'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < tabs.length; index++) ...[
            if (index > 0) const SizedBox(width: 5),
            SizedBox(
              width: index == 4 ? 112 : 96,
              child: _buildTab(tabs[index], index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = selectedTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2A241A) : const Color(0xFF151514),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? const Color(0xFFD7B56D) : const Color(0xFF38342D),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFFF1D084) : const Color(0xFFBDBDC2),
          ),
        ),
      ),
    );
  }
}

class OrderContent extends StatelessWidget {
  const OrderContent({
    super.key,
    required this.orders,
    required this.area,
    required this.tab,
  });

  final List<Map<String, dynamic>> orders;
  final String area;
  final int tab;

  String get statusLabel =>
      const ['すべて', '予約中', '未払い', '支払済み', 'キャンセル'][tab.clamp(0, 4)];

  List<Map<String, dynamic>> get filteredOrders {
    final status = switch (tab) {
      0 => null,
      1 => {'requesting', 'confirmed'},
      2 => {'unpaid'},
      3 => {'paid', 'completed'},
      _ => {'cancelled', 'rejected'},
    };
    if (status == null) return orders;
    return orders.where((order) => status.contains(order['status'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = filteredOrders;
    if (visibleOrders.isEmpty) {
      return _emptyState(context);
    }
    return Column(
      children: [
        for (final order in visibleOrders) ...[
          _OrderCard(order: order),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2A261F)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF242018),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 30,
              color: Color(0xFFD7B56D),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'オーダーはありません',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$statusLabelのオーダーはありません',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9C9CA1)),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 180,
            child: ThreeDButton(
              height: 34,
              fontSize: 12,
              textColor: const Color(0xFF201A10),
              shadowColor: const Color(0xFF8A682F),
              gradient: const LinearGradient(
                colors: [Color(0xFFF1D084), Color(0xFFC3944A)],
              ),
              label: 'ショップを探す',
              onTap: () {
                _openShopPage(context, area);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = '${order['status_text'] ?? order['status'] ?? ''}';
    final amount = (order['amount'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF5A4524)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order['shop_name'] ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                status,
                style: const TextStyle(color: Color(0xFF9ED56C), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _orderInfo('来店日時', '${order['visit_time'] ?? '-'}'),
          _orderInfo('人数', '${order['people_count'] ?? 1}人'),
          _orderInfo('担当キャスト', '${order['cast_name'] ?? 'なし'}'),
          const Divider(color: Color(0xFF2A261F), height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '注文番号  ${order['order_no'] ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF929096),
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '¥${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if ('${order['remark'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '備考: ${order['remark']}',
              style: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF929096), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFFE5E2DA), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.api, this.initialArea = '東京都'});

  final HomeApi api;
  final String initialArea;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late String _selectedArea = widget.initialArea;
  late HomeViewData _pageData = HomeViewData.empty(
    selectedArea: widget.initialArea,
  );
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadPageData(widget.initialArea);
    _loadProfile();
    _loadSupportUnread();
  }

  Future<void> _loadProfile() async {
    final cached = AppSession.cachedProfile;
    if (cached != null && mounted) {
      setState(() => _profile = cached);
    }
    try {
      final profile = await AuthApi().fetchProfile(token: AppSession.token);
      await AppSession.cacheProfile(profile);
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Keep the page usable if the profile endpoint is temporarily unavailable.
    }
  }

  Future<void> _loadSupportUnread() async {
    final conversation = await SupportApi().fetchLatest(
      token: AppSession.token,
    );
    if (!mounted) return;
    setState(() => AppSession.supportUnreadCount = conversation.unreadCount);
  }

  Future<void> _loadPageData(String area) async {
    final data = await widget.api.fetchHome(area: area);
    if (!mounted || area != _selectedArea) return;
    setState(() => _pageData = data);
  }

  void _selectArea(String area) {
    if (area == _selectedArea) return;
    setState(() {
      _selectedArea = area;
      _pageData = HomeViewData.empty(selectedArea: area);
    });
    _loadPageData(area);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ResponsiveMyScreen(
        data: _pageData,
        profile: _profile,
        onAreaSelected: _selectArea,
        onOrderTap: () => _openOrderPage(context, _selectedArea),
        onFavoriteShopsTap: () => _openFavoriteShopsPage(context),
        onFavoriteCastsTap: () => _openFavoriteCastsPage(context),
      ),
    );
  }
}

class ResponsiveMyScreen extends StatelessWidget {
  const ResponsiveMyScreen({
    super.key,
    required this.data,
    required this.profile,
    required this.onAreaSelected,
    required this.onOrderTap,
    required this.onFavoriteShopsTap,
    required this.onFavoriteCastsTap,
  });

  final HomeViewData data;
  final UserProfile? profile;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onOrderTap;
  final VoidCallback onFavoriteShopsTap;
  final VoidCallback onFavoriteCastsTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= 720
            ? MyDesktopScreen(
                data: data,
                profile: profile,
                onAreaSelected: onAreaSelected,
                onOrderTap: onOrderTap,
                onFavoriteShopsTap: onFavoriteShopsTap,
                onFavoriteCastsTap: onFavoriteCastsTap,
              )
            : MyMobileScreen(
                data: data,
                profile: profile,
                onAreaSelected: onAreaSelected,
                onOrderTap: onOrderTap,
                onFavoriteShopsTap: onFavoriteShopsTap,
                onFavoriteCastsTap: onFavoriteCastsTap,
              );
        return constraints.maxWidth >= 720 ? content : SafeArea(child: content);
      },
    );
  }
}

class MyMobileScreen extends StatelessWidget {
  const MyMobileScreen({
    super.key,
    required this.data,
    required this.profile,
    required this.onAreaSelected,
    required this.onOrderTap,
    required this.onFavoriteShopsTap,
    required this.onFavoriteCastsTap,
  });

  final HomeViewData data;
  final UserProfile? profile;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onOrderTap;
  final VoidCallback onFavoriteShopsTap;
  final VoidCallback onFavoriteCastsTap;

  @override
  Widget build(BuildContext context) {
    return _MyPageLayout(
      data: data,
      profile: profile,
      onAreaSelected: onAreaSelected,
      onOrderTap: onOrderTap,
      onFavoriteShopsTap: onFavoriteShopsTap,
      onFavoriteCastsTap: onFavoriteCastsTap,
      contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 22),
    );
  }
}

class MyDesktopScreen extends StatelessWidget {
  const MyDesktopScreen({
    super.key,
    required this.data,
    required this.profile,
    required this.onAreaSelected,
    required this.onOrderTap,
    required this.onFavoriteShopsTap,
    required this.onFavoriteCastsTap,
  });

  final HomeViewData data;
  final UserProfile? profile;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onOrderTap;
  final VoidCallback onFavoriteShopsTap;
  final VoidCallback onFavoriteCastsTap;

  @override
  Widget build(BuildContext context) {
    return _MyPageLayout(
      data: data,
      profile: profile,
      onAreaSelected: onAreaSelected,
      onOrderTap: onOrderTap,
      onFavoriteShopsTap: onFavoriteShopsTap,
      onFavoriteCastsTap: onFavoriteCastsTap,
      contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      maxContentWidth: 980,
    );
  }
}

class _MyPageLayout extends StatelessWidget {
  const _MyPageLayout({
    required this.data,
    required this.profile,
    required this.onAreaSelected,
    required this.onOrderTap,
    required this.onFavoriteShopsTap,
    required this.onFavoriteCastsTap,
    required this.contentPadding,
    this.maxContentWidth,
  });

  final HomeViewData data;
  final UserProfile? profile;
  final ValueChanged<String> onAreaSelected;
  final VoidCallback onOrderTap;
  final VoidCallback onFavoriteShopsTap;
  final VoidCallback onFavoriteCastsTap;
  final EdgeInsets contentPadding;
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: contentPadding,
      children: [
        SizedBox(height: 12),
        MyProfileCard(profile: profile),
        SizedBox(height: 10),
        MyBalanceCard(profile: profile),
        SizedBox(height: 14),
        MyMenuSection(
          onOrderTap: onOrderTap,
          onFavoriteShopsTap: onFavoriteShopsTap,
          onFavoriteCastsTap: onFavoriteCastsTap,
        ),
        SizedBox(height: 14),
        MyLogoutButton(),
      ],
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF050505),
      child: Column(
        children: [
          SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 10, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Center(
                    child: Text(
                      'マイページ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _openSettingsPage(context),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFFD7B56D),
                        size: 23,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: maxContentWidth == null
                ? content
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth!),
                      child: content,
                    ),
                  ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) {
              if (index == 0) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder<void>(
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                  ),
                );
              } else if (index == 1) {
                _openShopPage(context, data.area);
              } else if (index == 2) {
                _openCastPage(context, data.area);
              } else if (index == 3) {
                _openOrderPage(context, data.area);
              }
            },
          ),
        ],
      ),
    );
  }
}

class MyProfileCard extends StatefulWidget {
  const MyProfileCard({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<MyProfileCard> createState() => _MyProfileCardState();
}

class _MyProfileCardState extends State<MyProfileCard> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _editProfile() async {
    await _openMemberEditPage(context, _profile);
    try {
      final profile = await AuthApi().fetchProfile(token: AppSession.token);
      await AppSession.cacheProfile(profile);
      if (mounted) setState(() => _profile = profile);
    } catch (_) {
      // Keep the existing profile visible if refreshing fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final nickname = profile?.nickname.isNotEmpty == true
        ? profile!.nickname
        : 'ユーザー';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3B3427)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFF2A241A),
              shape: BoxShape.circle,
            ),
            child: profile?.avatar.isNotEmpty == true
                ? Image.network(
                    _resolvePlanImageUrl(profile!.avatar),
                    fit: BoxFit.cover,
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    size: 27,
                    color: Color(0xFFF1D084),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.levelName ?? '一般会員',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF1D084),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '有効期限 ${profile?.expiration ?? '無期限'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFBDBDC2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _editProfile,
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF6A5634)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: Color(0xFFF1D084),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '編集',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF1D084),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MemberEditPage extends StatefulWidget {
  const MemberEditPage({super.key, this.profile});
  final UserProfile? profile;

  @override
  State<MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<MemberEditPage> {
  late final _nickname = TextEditingController(
    text: widget.profile?.nickname ?? '',
  );
  late final _realName = TextEditingController(
    text: widget.profile?.realName ?? '',
  );
  late final _email = TextEditingController(text: widget.profile?.email ?? '');
  late final _nationality = TextEditingController(
    text: widget.profile?.nationality ?? '日本',
  );
  late final _postalCode = TextEditingController(
    text: widget.profile?.postalCode ?? '',
  );
  late final _address = TextEditingController(
    text: widget.profile?.address ?? '',
  );
  late final _buildingName = TextEditingController(
    text: widget.profile?.buildingName ?? '',
  );
  late final _mobile = TextEditingController(
    text: widget.profile?.mobile ?? '',
  );
  PickedAvatar? _avatarFile;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _nickname,
      _realName,
      _email,
      _nationality,
      _postalCode,
      _address,
      _buildingName,
      _mobile,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '情報編集',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _avatarEditor(),
                const SizedBox(height: 18),
                _field('ニックネーム', _nickname),
                _field('氏名', _realName),
                _field(
                  '携帯番号',
                  _mobile,
                  readOnly: true,
                  suffix: TextButton(
                    onPressed: () =>
                        _openPhoneVerificationPage(context, _mobile.text),
                    child: const Text('認証'),
                  ),
                ),
                _field('メールアドレス', _email, keyboard: TextInputType.emailAddress),
                _field('国籍', _nationality),
                _field('郵便番号', _postalCode, keyboard: TextInputType.number),
                _field('住所', _address),
                _field('建物名', _buildingName),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF171513),
                            border: Border.all(color: const Color(0xFF6A5634)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'キャンセル',
                            style: TextStyle(
                              color: Color(0xFFF1D084),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0BB69),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _saving ? '保存中...' : '保存する',
                            style: const TextStyle(
                              color: Color(0xFF171513),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboard,
    Widget? suffix,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: TextStyle(
        color: readOnly ? const Color(0xFF77777C) : Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF111110),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF4A3E30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF4A3E30)),
        ),
      ),
    ),
  );

  Widget _avatarEditor() {
    final avatar = widget.profile?.avatar ?? '';
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _saving ? null : _pickAvatar,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF171513),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF1D084),
                      width: 2,
                    ),
                  ),
                  child: _avatarFile?.bytes != null
                      ? Image.memory(_avatarFile!.bytes, fit: BoxFit.cover)
                      : avatar.isNotEmpty
                      ? Image.network(
                          _resolvePlanImageUrl(avatar),
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: Color(0xFFBDBDC2),
                          size: 42,
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0BB69),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF171513),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'プロフィール画像を変更',
              style: TextStyle(color: Color(0xFFF1D084), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await pickAvatar();
      if (!mounted || file == null) return;
      setState(() => _avatarFile = file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像を選択できませんでした: $error')));
    }
  }

  Future<void> _save() async {
    if (_nickname.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ニックネームを入力してください')));
      return;
    }
    setState(() => _saving = true);
    try {
      if (_avatarFile != null) {
        final avatar = await AuthApi().uploadAvatar(
          bytes: _avatarFile!.bytes,
          filename: _avatarFile!.filename,
          token: AppSession.token,
        );
        await AuthApi().saveAvatar(avatar: avatar, token: AppSession.token);
      }
      await AuthApi().saveMemberProfile(
        nickname: _nickname.text.trim(),
        realName: _realName.text.trim(),
        email: _email.text.trim(),
        nationality: _nationality.text.trim(),
        postalCode: _postalCode.text.trim(),
        address: _address.text.trim(),
        buildingName: _buildingName.text.trim(),
        token: AppSession.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('プロフィールを保存しました')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存に失敗しました')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key, required this.mobile});
  final String mobile;

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _mobile = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _mobile.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '電話番号認証',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '登録携帯番号',
                  style: TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.mobile.isEmpty ? '未登録' : widget.mobile,
                  style: const TextStyle(
                    color: Color(0xFF77777C),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _mobile,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: '新しい携帯番号',
                    hintText: '新しい携帯番号を入力',
                    labelStyle: TextStyle(color: Color(0xFFBDBDC2)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'SMS認証コード',
                    hintText: '認証コードを入力',
                    labelStyle: TextStyle(color: Color(0xFFBDBDC2)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _mobile.text.trim().isEmpty || _sent
                        ? null
                        : _sendCode,
                    child: Text(_sent ? '送信済み' : '認証コードを送信'),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed:
                        _sent &&
                            _mobile.text.trim().isNotEmpty &&
                            _code.text.trim().isNotEmpty
                        ? _verify
                        : null,
                    child: const Text('認証する'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _sendCode() async {
    try {
      await AuthApi().sendSmsCode(mobile: widget.mobile, scene: 'BGSJHM');
      if (mounted) {
        setState(() => _sent = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('登録携帯番号に認証コードを送信しました')));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('認証コードを送信できませんでした')));
    }
  }

  Future<void> _verify() async {
    try {
      await AuthApi().changeMobile(
        oldMobile: widget.mobile,
        mobile: _mobile.text.trim(),
        code: _code.text.trim(),
        token: AppSession.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('携帯番号を認証しました')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('認証に失敗しました')));
    }
  }
}

class MyBalanceCard extends StatelessWidget {
  const MyBalanceCard({super.key, this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF3B3427)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '残高',
                  style: TextStyle(fontSize: 10, color: Color(0xFFBDBDC2)),
                ),
                SizedBox(height: 3),
                Text(
                  '¥${(profile?.walletBalance ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF1D084),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'チャージ履歴',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD7B56D),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '会員特典',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E5E7),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  profile?.benefits.isNotEmpty == true
                      ? profile!.benefits.join('・')
                      : '特典なし',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Color(0xFF9B9B9F)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MyOutlineAction(
            label: '詳細',
            onTap: () => _showBenefitDetails(context),
          ),
        ],
      ),
    );
  }

  void _showBenefitDetails(BuildContext context) {
    final description = profile?.benefitDescription.isNotEmpty == true
        ? profile!.benefitDescription
        : '特典なし';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth - 20;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171716),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10),
        constraints: BoxConstraints(
          minWidth: dialogWidth,
          maxWidth: dialogWidth,
        ),
        title: const Text('会員特典'),
        content: Text(
          description,
          style: const TextStyle(fontSize: 13, color: Color(0xFFD7D7DA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _MyOutlineAction extends StatelessWidget {
  const _MyOutlineAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6A5634)),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF1D084),
            ),
          ),
        ),
      ),
    );
  }
}

class MyMenuSection extends StatelessWidget {
  const MyMenuSection({
    super.key,
    required this.onOrderTap,
    required this.onFavoriteShopsTap,
    required this.onFavoriteCastsTap,
  });

  final VoidCallback onOrderTap;
  final VoidCallback onFavoriteShopsTap;
  final VoidCallback onFavoriteCastsTap;

  @override
  Widget build(BuildContext context) {
    const menus = [
      (Icons.receipt_long_outlined, '予約履歴'),
      (Icons.storefront_outlined, 'お気に入り店舗'),
      (Icons.face_3_outlined, 'お気に入りキャスト'),
      (Icons.credit_card_outlined, '支払い方法'),
      (Icons.verified_user_outlined, '本人確認'),
      (Icons.confirmation_num_outlined, 'クーポン'),
      (Icons.notifications_none_rounded, 'お知らせ'),
      (Icons.tune_rounded, '通知設定'),
      (Icons.support_agent_outlined, 'お問い合わせ'),
      (Icons.description_outlined, '利用規約'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF2A261F)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < menus.length; index++) ...[
            InkWell(
              onTap: index == 0
                  ? onOrderTap
                  : index == 1
                  ? onFavoriteShopsTap
                  : index == 2
                  ? onFavoriteCastsTap
                  : index == 3
                  ? () => _openPaymentMethodsPage(context)
                  : index == 4
                  ? () => _openIdentityVerificationPage(context)
                  : index == 5
                  ? () => _openCouponPage(context)
                  : index == 6
                  ? () => _openNoticePage(context)
                  : index == 7
                  ? () => _openNotificationSettingsPage(context)
                  : index == 8
                  ? () => _openHelpSupportPage(context)
                  : index == 9
                  ? () => _openTermsPage(context)
                  : () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Icon(
                      menus[index].$1,
                      size: 21,
                      color: const Color(0xFFD7B56D),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            menus[index].$2,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5E5E7),
                            ),
                          ),
                          if (index == 7 &&
                              AppSession.supportUnreadCount > 0) ...[
                            const SizedBox(width: 7),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE34C55),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF77777C),
                    ),
                  ],
                ),
              ),
            ),
            if (index < menus.length - 1)
              const Divider(height: 1, color: Color(0xFF2A261F)),
          ],
        ],
      ),
    );
  }
}

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  late Future<List<TermData>> _termsFuture = TermsApi().fetchTerms(
    token: AppSession.token,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '利用規約',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TermData>>(
                future: _termsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF1D084),
                      ),
                    );
                  final terms = snapshot.data ?? const <TermData>[];
                  if (terms.isEmpty)
                    return const Center(
                      child: Text(
                        '現在、公開されている利用規約はありません',
                        style: TextStyle(
                          color: Color(0xFFAAA7A0),
                          fontSize: 14,
                        ),
                      ),
                    );
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: terms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111110),
                          border: Border.all(color: const Color(0xFF6A5634)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              term.title.isNotEmpty ? term.title : term.name,
                              style: const TextStyle(
                                color: Color(0xFFF1D084),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              term.content,
                              style: const TextStyle(
                                color: Color(0xFFE5E2DA),
                                fontSize: 14,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late Future<List<PaymentMethodData>> _methodsFuture = PaymentApi()
      .fetchMethods(token: AppSession.token);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '支払い方法',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: NoticeBellButton(iconSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<PaymentMethodData>>(
                future: _methodsFuture,
                builder: (context, snapshot) {
                  final methods = snapshot.data ?? const <PaymentMethodData>[];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      _PaymentMethodsIntro(count: methods.length),
                      const SizedBox(height: 16),
                      const _PaymentMethodsSectionTitle(title: 'カード'),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF1D084),
                            ),
                          ),
                        )
                      else if (methods.isEmpty)
                        const _EmptyPaymentMethods()
                      else
                        for (final method in methods) ...[
                          _SavedCardTile(
                            brand: method.brand,
                            number: '••••  ••••  ••••  ${method.last4}',
                            holder: method.holderName,
                            expiry: method.expiry,
                            color: const Color(0xFFE0B44F),
                          ),
                          const SizedBox(height: 8),
                        ],
                      _AddCardButton(
                        onTap: () async {
                          _openProtectedSubPage(
                            context,
                            const PaymentCardEditPage(),
                          );
                          if (mounted) {
                            setState(() {
                              _methodsFuture = PaymentApi().fetchMethods(
                                token: AppSession.token,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsIntro extends StatelessWidget {
  const _PaymentMethodsIntro({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171716),
        border: Border.all(color: const Color(0xFF8D6227)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF2A241A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_outlined,
              color: Color(0xFFF1D084),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '登録済みのお支払い方法',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${count}件',
            style: TextStyle(
              color: Color(0xFFF1D084),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPaymentMethods extends StatelessWidget {
  const _EmptyPaymentMethods();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 22),
    child: Center(
      child: Text(
        '登録されているカードはありません',
        style: TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
      ),
    ),
  );
}

class _PaymentMethodsSectionTitle extends StatelessWidget {
  const _PaymentMethodsSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
    required this.color,
  });
  final String brand;
  final String number;
  final String holder;
  final String expiry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF6A5634)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                brand,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Color(0xFFAAA39A), size: 19),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  holder,
                  style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 9),
                ),
              ),
              Text(
                expiry,
                style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onTap ?? () => _openPaymentCardEditPage(context),
        icon: const Icon(Icons.add_card_outlined, size: 17),
        label: const Text('新しいカードを追加'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF1D084),
          side: const BorderSide(color: Color(0xFF8D6227)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class PaymentCardEditPage extends StatefulWidget {
  const PaymentCardEditPage({super.key});

  @override
  State<PaymentCardEditPage> createState() => _PaymentCardEditPageState();
}

class _PaymentCardEditPageState extends State<PaymentCardEditPage> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _holderController = TextEditingController();
  bool _isDefault = true;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  void _saveCard() {
    final number = _cardNumberController.text.replaceAll(RegExp(r'\D'), '');
    final expiry = _expiryController.text.trim();
    final cvc = _cvcController.text.replaceAll(RegExp(r'\D'), '');
    final validExpiry = RegExp(
      r'^(0[1-9]|1[0-2])\s*/\s*\d{2}$',
    ).hasMatch(expiry);
    if (!RegExp(r'^\d{13,19}$').hasMatch(number) ||
        !validExpiry ||
        !RegExp(r'^\d{3,4}$').hasMatch(cvc) ||
        _holderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('カード情報の形式を確認してください')));
      return;
    }
    _submitCard(number, expiry, cvc);
  }

  Future<void> _submitCard(String number, String expiry, String cvc) async {
    try {
      await PaymentApi().createCard(
        token: AppSession.token,
        cardNumber: number,
        expiry: expiry,
        cvc: cvc,
        holderName: _holderController.text.trim(),
        isDefault: _isDefault,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'.replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _onCardNumberChanged(String value) {
    final digits = value
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, value.replaceAll(RegExp(r'\D'), '').length.clamp(0, 19));
    final formatted = _formatCardNumber(digits);
    if (_cardNumberController.text != formatted) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  String _formatCardNumber(String digits) {
    final groups = <String>[];
    for (var index = 0; index < digits.length; index += 4) {
      groups.add(digits.substring(index, (index + 4).clamp(0, digits.length)));
    }
    return groups.join(' ');
  }

  void _onExpiryChanged(String value) {
    final digits = value
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, value.replaceAll(RegExp(r'\D'), '').length.clamp(0, 4));
    final formatted = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    if (_expiryController.text != formatted) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'カード情報',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: NoticeBellButton(iconSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  _CardPreview(
                    cardNumber: _cardNumberController.text,
                    holder: _holderController.text,
                    expiry: _expiryController.text,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'カード情報を入力',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _CardInputField(
                    label: 'カード番号',
                    hint: '1234 5678 9012 3456',
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final digits = newValue.text
                            .replaceAll(RegExp(r'\D'), '')
                            .substring(
                              0,
                              newValue.text
                                  .replaceAll(RegExp(r'\D'), '')
                                  .length
                                  .clamp(0, 19),
                            );
                        final formatted = _groupCardDigits(digits);
                        return TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }),
                    ],
                    onChanged: _onCardNumberChanged,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CardInputField(
                          label: '有効期限',
                          hint: 'MM / YY',
                          controller: _expiryController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                            signed: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          onChanged: _onExpiryChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CardInputField(
                          label: 'セキュリティコード',
                          hint: 'CVC',
                          controller: _cvcController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CardInputField(
                    label: 'カード名義',
                    hint: 'TARO YAMADA',
                    controller: _holderController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    dense: true,
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    title: const Text(
                      'デフォルトのお支払い方法に設定',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    activeColor: const Color(0xFFF1D084),
                    activeTrackColor: const Color(0xFF805E26),
                    inactiveThumbColor: const Color(0xFFAAA39A),
                    inactiveTrackColor: const Color(0xFF39352F),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saveCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B84D),
                        foregroundColor: const Color(0xFF17130D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('保存する'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'カード情報は安全な決済サービスで処理されます。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF77736C), fontSize: 9),
                  ),
                ],
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.cardNumber,
    required this.holder,
    required this.expiry,
  });
  final String cardNumber;
  final String holder;
  final String expiry;

  @override
  Widget build(BuildContext context) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final number = digits.isEmpty
        ? '••••  ••••  ••••  1234'
        : _groupCardDigits(digits);
    return Container(
      height: 142,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3517), Color(0xFF17130D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF8D6227)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '新しいカード',
                style: TextStyle(color: Color(0xFFF1D084), fontSize: 9),
              ),
              Spacer(),
              Text(
                'CARD',
                style: TextStyle(
                  color: Color(0xFFF1D084),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 31,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFD6B562),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  holder.trim().isEmpty ? 'TARO YAMADA' : holder.toUpperCase(),
                  style: const TextStyle(color: Color(0xFFD8D0C2), fontSize: 8),
                ),
              ),
              Text(
                expiry.trim().isEmpty ? 'MM/YY' : expiry,
                style: const TextStyle(color: Color(0xFFD8D0C2), fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _groupCardDigits(String digits) {
  final groups = <String>[];
  for (var index = 0; index < digits.length; index += 4) {
    groups.add(digits.substring(index, (index + 4).clamp(0, digits.length)));
  }
  return groups.join(' ');
}

class _CardInputField extends StatelessWidget {
  const _CardInputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.inputFormatters,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    onChanged: onChanged,
    inputFormatters: inputFormatters,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFFF1D084), fontSize: 10),
      hintStyle: const TextStyle(color: Color(0xFF77736C), fontSize: 11),
      filled: true,
      fillColor: const Color(0xFF111110),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF6A5634)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFF1D084)),
      ),
    ),
  );
}

class _OtherPaymentTile extends StatelessWidget {
  const _OtherPaymentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3B3427)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFF1D084), size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
        ),
        const SizedBox(width: 5),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF77777C),
          size: 19,
        ),
      ],
    ),
  );
}

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  String _selectedMethod = 'マイナンバーカード';

  void _showUploadMessage(BuildContext context, String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$titleをアップロードしてください')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '本人確認',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: NoticeBellButton(iconSize: 24),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  const _IdentityStatusCard(),
                  const SizedBox(height: 16),
                  const Text(
                    '認証方法を選択',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _IdentityMethodTile(
                    icon: Icons.badge_outlined,
                    title: 'マイナンバーカード',
                    detail: '顔写真付きのマイナンバーカード',
                    selected: _selectedMethod == 'マイナンバーカード',
                    onTap: () => setState(() => _selectedMethod = 'マイナンバーカード'),
                  ),
                  _IdentityMethodTile(
                    icon: Icons.directions_car_outlined,
                    title: '運転免許証',
                    detail: '日本国内で発行された運転免許証',
                    selected: _selectedMethod == '運転免許証',
                    onTap: () => setState(() => _selectedMethod = '運転免許証'),
                  ),
                  _IdentityMethodTile(
                    icon: Icons.menu_book_outlined,
                    title: 'パスポート',
                    detail: '顔写真と氏名が確認できるパスポート',
                    selected: _selectedMethod == 'パスポート',
                    onTap: () => setState(() => _selectedMethod = 'パスポート'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '外国籍の方',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _IdentityMethodTile(
                    icon: Icons.credit_card_outlined,
                    title: '在留カード',
                    detail: '有効期限内の在留カード',
                    selected: _selectedMethod == '在留カード',
                    onTap: () => setState(() => _selectedMethod = '在留カード'),
                  ),
                  const _IdentityDocumentInfo(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _openProtectedSubPage(
                        context,
                        IdentityDocumentUploadPage(method: _selectedMethod),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B84D),
                        foregroundColor: const Color(0xFF17130D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text('$_selectedMethodで本人確認を提出する'),
                    ),
                  ),
                ],
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdentityDocumentUploadPage extends StatefulWidget {
  const IdentityDocumentUploadPage({super.key, required this.method});
  final String method;

  @override
  State<IdentityDocumentUploadPage> createState() =>
      _IdentityDocumentUploadPageState();
}

class _IdentityDocumentUploadPageState
    extends State<IdentityDocumentUploadPage> {
  PlatformFile? _front;
  PlatformFile? _back;

  Future<void> _pickDocument(bool front) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      setState(() {
        if (front) {
          _front = result.files.single;
        } else {
          _back = result.files.single;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('画像を選択できませんでした')));
      }
    }
  }

  void _submit() {
    if (_front == null || _back == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('証明書の表面と裏面を選択してください')));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => IdentityVerificationCompletePage(method: widget.method),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '書類をアップロード',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171716),
                      border: Border.all(color: const Color(0xFF8D6227)),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${widget.method}の表面と裏面をアップロードしてください',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DocumentUploadTile(
                    title: '表面',
                    file: _front,
                    onTap: () => _pickDocument(true),
                  ),
                  const SizedBox(height: 10),
                  _DocumentUploadTile(
                    title: '裏面',
                    file: _back,
                    onTap: () => _pickDocument(false),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '文字が読めるように、明るい場所で撮影してください。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6B84D),
                        foregroundColor: const Color(0xFF17130D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('本人確認を提出する'),
                    ),
                  ),
                ],
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdentityVerificationCompletePage extends StatelessWidget {
  const IdentityVerificationCompletePage({super.key, required this.method});
  final String method;

  String get submittedDate {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '本人確認書類',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111110),
                    border: Border.all(color: const Color(0xFF3B3427)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Column(
                    children: [
                      _IdentityCompleteCheck(),
                      SizedBox(height: 16),
                      Text(
                        '書類を提出しました',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        '本人確認書類の提出が完了しました。\n確認が完了するまでしばらくお待ちください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFAAA39A),
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 11),
                      Text(
                        '審査中',
                        style: TextStyle(
                          color: Color(0xFFF1D084),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111110),
                    border: Border.all(color: const Color(0xFF3B3427)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '受理内容',
                        style: TextStyle(
                          color: Color(0xFFF1D084),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _IdentityCompleteRow(label: '書類', value: method),
                      const Divider(height: 15, color: Color(0xFF39352F)),
                      _IdentityCompleteRow(label: '提出日', value: submittedDate),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171716),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF1D084),
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '審査結果はマイページの本人確認から確認できます。',
                          style: TextStyle(
                            color: Color(0xFFAAA39A),
                            fontSize: 9,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () =>
                        _openMyPage(context, AppSession.currentArea),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE6B84D),
                      foregroundColor: const Color(0xFF17130D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('マイページへ戻る'),
                  ),
                ),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) => _handleDetailFooterNavigation(
              context,
              index,
              AppSession.currentArea,
            ),
          ),
        ],
      ),
    ),
  );
}

class _IdentityCompleteCheck extends StatelessWidget {
  const _IdentityCompleteCheck();

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE6B84D), width: 1.5),
      color: const Color(0xFF211C14),
    ),
    child: const Icon(Icons.check_rounded, color: Color(0xFFF1D084), size: 32),
  );
}

class _IdentityCompleteRow extends StatelessWidget {
  const _IdentityCompleteRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 72,
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _DocumentUploadTile extends StatelessWidget {
  const _DocumentUploadTile({
    required this.title,
    required this.file,
    required this.onTap,
  });
  final String title;
  final PlatformFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 154,
          decoration: BoxDecoration(
            color: const Color(0xFF111110),
            border: Border.all(
              color: hasFile
                  ? const Color(0xFFE6B84D)
                  : const Color(0xFF6A5634),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: file?.bytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(file!.bytes!, fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xCC050505),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          child: Text(
                            file!.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '$titleを選択',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'タップして画像を追加',
                      style: TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IdentityStatusCard extends StatelessWidget {
  const _IdentityStatusCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
    decoration: BoxDecoration(
      color: const Color(0xFF171716),
      border: Border.all(color: const Color(0xFF8D6227)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2A241A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFF1D084),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本人確認ステータス',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              _IdentityStatusLabel(label: '未認証', active: true),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IdentityStatusLabel extends StatelessWidget {
  const _IdentityStatusLabel({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE6B84D) : const Color(0xFF77736C),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFFF1D084) : const Color(0xFFAAA39A),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _IdentityMethodTile extends StatelessWidget {
  const _IdentityMethodTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2B2111) : const Color(0xFF111110),
        border: Border.all(
          color: selected ? const Color(0xFFE6B84D) : const Color(0xFF6A5634),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF1D084), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 9),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? const Color(0xFFE6B84D) : const Color(0xFF77736C),
            size: 21,
          ),
        ],
      ),
    ),
  );
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    this.isDone = false,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final bool isDone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(11, 10, 10, 10),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF6A5634)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: isDone ? const Color(0xFF72D65B) : const Color(0xFFF1D084),
          size: 21,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: isDone
                          ? const Color(0xFF72D65B)
                          : const Color(0xFFF1D084),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton(
                      onPressed: onAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF1D084),
                        side: const BorderSide(color: Color(0xFF8D6227)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(actionLabel!),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _IdentityDocumentInfo extends StatelessWidget {
  const _IdentityDocumentInfo();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3B3427)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '提出できる書類',
          style: TextStyle(
            color: Color(0xFFF1D084),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          '運転免許証、マイナンバーカード、在留カード',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        SizedBox(height: 5),
        Text(
          '写真が鮮明で、有効期限内の書類をご用意ください。',
          style: TextStyle(color: Color(0xFFAAA39A), fontSize: 9),
        ),
      ],
    ),
  );
}

class MyLogoutButton extends StatelessWidget {
  const MyLogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1B1A18),
                title: const Text(
                  'ログアウト',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                content: const Text(
                  'ログアウトしますか？',
                  style: TextStyle(color: Color(0xFFBDBDC2), fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC3944A),
                      foregroundColor: const Color(0xFF201A10),
                    ),
                    child: const Text('ログアウト'),
                  ),
                ],
              );
            },
          );

          if (!context.mounted || shouldLogout != true) return;
          await AppSession.clear();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder<void>(
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => const LoginPage(),
            ),
            (_) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 17),
        label: const Text('ログアウト'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE08A8A),
          side: const BorderSide(color: Color(0xFF6D3E3E)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class CastDetailPage extends StatefulWidget {
  const CastDetailPage({super.key, required this.cast});

  final CastData cast;

  @override
  State<CastDetailPage> createState() => _CastDetailPageState();
}

class _CastDetailPageState extends State<CastDetailPage> {
  int _selectedTab = 0;
  String _reviewFilter = 'すべて';
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (!AppSession.isAuthenticated || widget.cast.id <= 0) return;
    try {
      final favorited = await FavoriteApi().fetchCastStatus(
        token: AppSession.token,
        castId: widget.cast.id,
      );
      if (mounted) setState(() => _isFavorite = favorited);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (!AppSession.isAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('お気に入り登録にはログインが必要です')));
      return;
    }
    if (_favoriteLoading) return;
    setState(() => _favoriteLoading = true);
    try {
      final favorited = await FavoriteApi().toggleCast(
        token: AppSession.token,
        castId: widget.cast.id,
      );
      if (mounted) setState(() => _isFavorite = favorited);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('お気に入りを更新できませんでした')));
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cast = widget.cast;
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text(
                          'キャスト詳細',
                          style: TextStyle(
                            color: Color(0xFFF0C96D),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFFE2B85F),
                              size: 19,
                            ),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: NoticeBellButton(iconSize: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 88),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _CastDetailHero(
                          cast: cast,
                          isFavorite: _isFavorite,
                          onFavorite: _toggleFavorite,
                        ),
                        const SizedBox(height: 8),
                        _CastDetailTabs(
                          selectedIndex: _selectedTab,
                          onChanged: (value) =>
                              setState(() => _selectedTab = value),
                        ),
                        const SizedBox(height: 14),
                        if (_selectedTab == 0)
                          _CastProfileContent(cast: cast)
                        else if (_selectedTab == 1)
                          _CastPhotosContent(cast: cast)
                        else if (_selectedTab == 2)
                          _CastAttendanceContent(cast: cast)
                        else
                          _CastReviewsContent(
                            cast: cast,
                            filter: _reviewFilter,
                            onFilterChanged: (value) =>
                                setState(() => _reviewFilter = value),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FooterNavigation(
                activeIndex: 2,
                onItemTap: (index) =>
                    _handleDetailFooterNavigation(context, index, cast.area),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastDetailHero extends StatelessWidget {
  const _CastDetailHero({
    required this.cast,
    required this.isFavorite,
    required this.onFavorite,
  });

  final CastData cast;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF8D6227)),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 124,
              height: 174,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CastAvatarImage(cast: cast, width: 124, height: 174),
              ),
            ),
          ),
          Positioned(
            left: 134,
            right: 8,
            top: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CastStatusPill(cast: cast),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(right: 54),
                  child: Text(
                    cast.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    CastShopMiniCard(
                      shopName: cast.shop.isNotEmpty ? cast.shop : '—',
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 22,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final tag in cast.tags) ...[
                                _CastListTag(label: tag),
                                const SizedBox(width: 4),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _CastMetric(
                      value: cast.rating.isNotEmpty ? cast.rating : '4.5',
                      label: '評価',
                    ),
                    const SizedBox(width: 6),
                    _CastMetric(
                      value: cast.height > 0 ? '${cast.height}cm' : '—',
                      label: '身長',
                    ),
                    const SizedBox(width: 6),
                    _CastMetric(
                      value: cast.isNew
                          ? '新人'
                          : cast.isPopular
                          ? '人気'
                          : cast.isRecommended
                          ? 'おすすめ'
                          : '—',
                      label: 'フラグ',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 14,
            child: Row(
              children: [
                IconButton(
                  onPressed: onFavorite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: Color(0xFFE2B85F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.share_outlined,
                  color: Color(0xFFE2B85F),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CastStatusPill extends StatelessWidget {
  const _CastStatusPill({required this.cast});
  final CastData cast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Color(cast.color)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color(cast.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          cast.badge,
          style: TextStyle(
            color: Color(cast.color),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CastMetric extends StatelessWidget {
  const _CastMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF171513),
      border: Border.all(color: const Color(0xFF5E461F)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE4C574),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF968D80), fontSize: 7),
        ),
      ],
    ),
  );
}

class CastShopMiniCard extends StatelessWidget {
  const CastShopMiniCard({super.key, required this.shopName});
  final String shopName;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 112),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF171513),
      border: Border.all(color: const Color(0xFF5E461F)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.storefront_outlined,
          size: 13,
          color: Color(0xFFD7A952),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            shopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFD4D0CA), fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class _CastListTag extends StatelessWidget {
  const _CastListTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0x1AD7B56D),
      border: Border.all(color: const Color(0x66D7B56D)),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 8,
        color: Color(0xFFD7B56D),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CastDetailTabs extends StatelessWidget {
  const _CastDetailTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['プロフィール', '写真', '出勤', '口コミ'];
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF11100F),
        border: Border.all(color: const Color(0xFF775722)),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? const Color(0xFFE7BD6B)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selectedIndex == index
                          ? const Color(0xFF1D160B)
                          : const Color(0xFFD2D0CC),
                      fontSize: 12,
                      height: 1,
                      fontWeight: selectedIndex == index
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CastReviewsContent extends StatelessWidget {
  const _CastReviewsContent({
    required this.cast,
    required this.filter,
    required this.onFilterChanged,
  });
  final CastData cast;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final reviews = cast.reviews;
    if (reviews.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CastSectionTitle(title: '口コミ', detail: ''),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text(
              'まだ口コミはありません。',
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
                color: Color(0xFFD0D0D2),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CastSectionTitle(title: '口コミ', detail: '${reviews.length}件'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111110),
            border: Border.all(color: const Color(0xFF8D6227)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 118,
                child: Column(
                  children: [
                    Text(
                      cast.rating.isNotEmpty ? cast.rating : '4.5',
                      style: TextStyle(
                        color: Color(0xFFF1D084),
                        fontSize: 46,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      '★★★★★',
                      style: TextStyle(color: Color(0xFFF1D084), fontSize: 20),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'また会いたい評価が\n高いキャストです',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFE0DDD7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  children: [
                    _CastRatingLine(label: '接客', value: '5.0'),
                    _CastRatingLine(label: '会話', value: '4.9'),
                    _CastRatingLine(label: '雰囲気', value: '4.8'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['すべて', '高評価', '接客', '会話', '初回']
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CastReviewFilter(
                      label: label,
                      selected: filter == label,
                      onTap: () => onFilterChanged(label),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        for (final review in reviews)
          _CastReviewCard(
            review: (
              '${review['name'] ?? 'U'}'.isNotEmpty
                  ? '${review['name'] ?? 'U'}'[0]
                  : 'U',
              '${review['name'] ?? ''}',
              '${review['content'] ?? ''}',
              '${review['rating'] ?? ''}',
              '${review['date'] ?? ''}',
            ),
          ),
      ],
    );
  }
}

class _CastSectionTitle extends StatelessWidget {
  const _CastSectionTitle({required this.title, required this.detail});
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 3, height: 28, color: const Color(0xFFF1D084)),
      const SizedBox(width: 9),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 13),
      Text(
        detail,
        style: const TextStyle(color: Color(0xFFBDB9B1), fontSize: 14),
      ),
    ],
  );
}

class _CastRatingLine extends StatelessWidget {
  const _CastRatingLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFE3DFD9), fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: .9,
              minHeight: 7,
              backgroundColor: Color(0xFF3A3732),
              color: Color(0xFFD7A952),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(color: Color(0xFFE3DFD9), fontSize: 13),
        ),
      ],
    ),
  );
}

class _CastReviewFilter extends StatelessWidget {
  const _CastReviewFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 82,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD7AD5A) : const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF775223)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF1D160B) : const Color(0xFFD4D0CA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CastReviewCard extends StatelessWidget {
  const _CastReviewCard({required this.review});
  final (String, String, String, String, String) review;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF8D6227)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD7A952)),
          ),
          child: Text(
            review.$1,
            style: const TextStyle(
              color: Color(0xFFF1D084),
              fontSize: 22,
              fontFamily: 'serif',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.$2,
                      style: const TextStyle(
                        color: Color(0xFFE3DFD9),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '★★★★★ ${review.$4}',
                    style: const TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                review.$5,
                style: TextStyle(color: Color(0xFFBDB9B1), fontSize: 11),
              ),
              const SizedBox(height: 5),
              Text(
                review.$3,
                style: const TextStyle(
                  color: Color(0xFFE3DFD9),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CastProfileContent extends StatelessWidget {
  const _CastProfileContent({required this.cast});
  final CastData cast;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CastSectionTitle(title: 'プロフィール', detail: ''),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
        decoration: BoxDecoration(
          color: const Color(0xFF111110),
          border: Border.all(color: const Color(0xFF8D6227)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _CastProfileRow(
              '年齢',
              cast.age > 0 ? '${cast.age}歳' : '—',
              'スタイル',
              _profileValue(cast.style),
            ),
            _CastProfileRow(
              '血液型',
              _profileValue(cast.bloodType),
              '出身地',
              _profileValue(cast.birthplace),
            ),
            _CastProfileRow(
              '喫煙・飲酒',
              _profileValue(cast.smokingDrinking),
              '趣味',
              _profileValue(cast.hobby),
            ),
            _CastProfileRow(
              '出勤頻度',
              _profileValue(cast.attendanceFrequency),
              '男の好みのタイプ',
              _profileValue(cast.preferredMaleType),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const _CastSectionTitle(title: '自己紹介', detail: ''),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111110),
          border: Border.all(color: const Color(0xFF8D6227)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _profileValue(cast.profile),
          style: const TextStyle(
            color: Color(0xFFE3DFD9),
            fontSize: 12,
            height: 1.65,
          ),
        ),
      ),
      const SizedBox(height: 18),
      const _CastSectionTitle(title: '所属店舗', detail: ''),
      const SizedBox(height: 10),
      _CastShopCard(cast: cast),
    ],
  );

  String _profileValue(String value) => value.trim().isEmpty ? '—' : value;
}

class _CastProfileRow extends StatelessWidget {
  const _CastProfileRow(
    this.leftLabel,
    this.leftValue,
    this.rightLabel,
    this.rightValue,
  );
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) => Container(
    height: 37,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF342C21))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            leftLabel,
            style: const TextStyle(color: Color(0xFF9B8E78), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            leftValue,
            style: const TextStyle(
              color: Color(0xFFE1C67F),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 62,
          child: Text(
            rightLabel,
            style: const TextStyle(color: Color(0xFF9B8E78), fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            rightValue,
            style: const TextStyle(
              color: Color(0xFFE1C67F),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CastShopCard extends StatelessWidget {
  const _CastShopCard({required this.cast});
  final CastData cast;

  ShopData _shopData() => ShopData(
    id: cast.shopId,
    name: cast.shop,
    area: cast.area,
    description: '',
    address: '',
    station: '',
    isRecommended: false,
    businessStatus: cast.shopStatus == '営業中' ? '営業中' : '休み',
    businessHours: '',
    bookingEnabled: false,
    shopImages: cast.shopImage.isEmpty ? const [] : [cast.shopImage],
    packageSets: const [],
    casts: const [],
    reviews: const [],
    price: '',
    score: '4.5',
    count: '',
    tags: const [],
    asset: cast.shopImage.isNotEmpty
        ? cast.shopImage
        : 'assets/home/shop-luxe-v1.png',
    fallbackAsset: 'assets/home/shop-luxe-v1.png',
    rank: '',
    ribbonColor: 0xFFD7A952,
    isSearchFallback: false,
  );

  @override
  Widget build(BuildContext context) => Container(
    height: 108,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF8D6227)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          height: double.infinity,
          child: cast.shopImage.isNotEmpty
              ? Image.network(
                  cast.shopImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/home/shop-luxe-v1.png',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset('assets/home/shop-luxe-v1.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cast.shop.isNotEmpty ? cast.shop : '所属店舗未設定',
                style: TextStyle(
                  color: Color(0xFFE9D9AE),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                cast.area.isNotEmpty ? cast.area : '—',
                style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 10),
              ),
              SizedBox(height: 6),
              Text(
                cast.shopStatus == '営業中' ? '● 営業中' : '● 休み',
                style: TextStyle(
                  color: cast.shopStatus == '営業中'
                      ? Color(0xFF45D48B)
                      : Color(0xFFE06A6A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 82,
                  child: GoldButton(
                    height: 28,
                    fontSize: 10,
                    label: '店舗を見る',
                    onTap: cast.shopId > 0
                        ? () => _openShopDetail(context, _shopData())
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CastAttendanceContent extends StatefulWidget {
  const _CastAttendanceContent({required this.cast});
  final CastData cast;

  @override
  State<_CastAttendanceContent> createState() => _CastAttendanceContentState();
}

class _CastAttendanceContentState extends State<_CastAttendanceContent> {
  late final Future<List<CastScheduleData>> _scheduleFuture = HomeApi()
      .fetchCastSchedule(widget.cast.id);
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CastScheduleData>>(
      future: _scheduleFuture,
      builder: (context, snapshot) =>
          _buildCalendar(context, snapshot.data ?? const []),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    List<CastScheduleData> schedules,
  ) {
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final byDate = <String, List<CastScheduleData>>{};
    for (final schedule in schedules) {
      byDate.putIfAbsent(schedule.workDate, () => []).add(schedule);
    }
    final days = List.generate(
      31,
      (index) => firstDay.add(Duration(days: index)),
    );
    final selectedKey = _calendarDateKey(_selectedDate);
    final selectedSchedules = byDate[selectedKey] ?? const [];
    final nearestDay = days.firstWhere(
      (day) => (byDate[_calendarDateKey(day)] ?? const []).isNotEmpty,
      orElse: () => firstDay,
    );
    final nearestSchedules = byDate[_calendarDateKey(nearestDay)] ?? const [];
    final displayDay = selectedSchedules.isNotEmpty
        ? _selectedDate
        : nearestDay;
    final displaySchedules = selectedSchedules.isNotEmpty
        ? selectedSchedules
        : nearestSchedules;
    final weekEnd = firstDay.add(Duration(days: 6 - (firstDay.weekday % 7)));
    final weekSchedules = <DateTime, List<CastScheduleData>>{};
    for (final day in days) {
      if (day.isAfter(weekEnd)) break;
      final daySchedules = byDate[_calendarDateKey(day)] ?? const [];
      if (daySchedules.isNotEmpty) weekSchedules[day] = daySchedules;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CastSectionTitle(title: '出勤', detail: '近1ヶ月'),
        const SizedBox(height: 10),
        _CastDateScroller(
          days: days,
          selectedDate: _selectedDate,
          schedules: byDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 14),
        _CastSchedulePanel(
          title: displayDay.isAtSameMomentAs(firstDay)
              ? '本日の出勤時間'
              : '${displayDay.month}/${displayDay.day}の出勤時間',
          schedules: displaySchedules,
        ),
        const SizedBox(height: 14),
        _CastSchedulePanel(title: '今週の出勤予定', schedulesByDate: weekSchedules),
      ],
    );
  }
}

class _CastDateScroller extends StatelessWidget {
  const _CastDateScroller({
    required this.days,
    required this.selectedDate,
    required this.schedules,
    required this.onSelected,
  });
  final List<DateTime> days;
  final DateTime selectedDate;
  final Map<String, List<CastScheduleData>> schedules;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF8D6227)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final day = days[index];
          final key = _calendarDateKey(day);
          final isSelected = _calendarDateKey(selectedDate) == key;
          final isWorking = (schedules[key] ?? const []).any(
            (schedule) => schedule.attendanceStatus != 'off',
          );
          return GestureDetector(
            onTap: () => onSelected(day),
            child: Container(
              width: 49,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE6B84D)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(day.weekday),
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF17130D)
                          : const Color(0xFFAAA39A),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF17130D)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isWorking
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF72D65B),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Text(
                          'X',
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF17130D)
                                : const Color(0xFFB86D6D),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _calendarDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _weekday(int weekday) =>
    const ['日', '月', '火', '水', '木', '金', '土'][weekday % 7];

class _CastSchedulePanel extends StatelessWidget {
  const _CastSchedulePanel({
    required this.title,
    this.schedules = const [],
    this.schedulesByDate = const {},
  });
  final String title;
  final List<CastScheduleData> schedules;
  final Map<DateTime, List<CastScheduleData>> schedulesByDate;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (schedulesByDate.isNotEmpty) {
      for (final entry in schedulesByDate.entries) {
        rows.add(
          _scheduleRow('${entry.key.month}/${entry.key.day}', entry.value),
        );
      }
    } else if (schedules.isNotEmpty) {
      rows.add(_scheduleRow('', schedules));
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF8D6227)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF1D084),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text(
              '出勤予定はありません',
              style: TextStyle(color: Color(0xFFAAA39A), fontSize: 13),
            )
          else
            ...rows,
        ],
      ),
    );
  }

  Widget _scheduleRow(String date, List<CastScheduleData> entries) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            date,
            style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 13),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 7,
            runSpacing: 6,
            children: entries
                .map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF211C14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${entry.startTime}〜${entry.endTime}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class _CastPhotosContent extends StatelessWidget {
  const _CastPhotosContent({required this.cast});
  final CastData cast;
  List<String> get photos {
    final images = <String>[];
    if (cast.asset.isNotEmpty) images.add(cast.asset);
    images.addAll(cast.galleryImages.where((image) => image.isNotEmpty));
    return images.toSet().toList();
  }

  Widget _photoImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(cast.fallbackAsset, fit: BoxFit.cover),
      );
    }
    return Image.asset(path, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _CastSectionTitle(title: '写真', detail: ''),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () =>
              _ShopDetailPhoto._showFullscreenPhoto(context, index, photos),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: _photoImage(photos[index]),
          ),
        ),
      ),
    ],
  );
}

class CastPage extends StatefulWidget {
  const CastPage({super.key, required this.api, this.initialArea = '東京都'});

  final HomeApi api;
  final String initialArea;

  @override
  State<CastPage> createState() => _CastPageState();
}

class _CastPageState extends State<CastPage> {
  late String _selectedArea = widget.initialArea;
  String _keyword = '';
  String _attendanceStatus = '';
  String _castSort = 'recommended';
  late final TextEditingController _searchController = TextEditingController();
  late Future<HomeViewData> _castData = widget.api.fetchHome(
    area: widget.initialArea,
    attendanceStatus: _attendanceStatus,
    castSort: _castSort,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectArea(String area) {
    if (area == _selectedArea) return;
    setState(() {
      _selectedArea = area;
      AppSession.currentArea = area;
      _castData = widget.api.fetchHome(
        area: area,
        keyword: _keyword,
        attendanceStatus: _attendanceStatus,
        castSort: _castSort,
      );
    });
  }

  void _search(String keyword) {
    final nextKeyword = keyword.trim();
    if (nextKeyword == _keyword) return;
    setState(() {
      _keyword = nextKeyword;
      _castData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        attendanceStatus: _attendanceStatus,
        castSort: _castSort,
      );
    });
  }

  void _selectAttendanceStatus(String status) {
    if (status == _attendanceStatus) return;
    setState(() {
      _attendanceStatus = status;
      _castData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        attendanceStatus: _attendanceStatus,
        castSort: _castSort,
      );
    });
  }

  void _selectCastSort(String sort) {
    if (sort == _castSort) return;
    setState(() {
      _castSort = sort;
      _castData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        attendanceStatus: _attendanceStatus,
        castSort: sort,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<HomeViewData>(
        future: _castData,
        builder: (context, snapshot) {
          return ResponsiveCastScreen(
            data:
                snapshot.data ??
                HomeViewData.empty(selectedArea: _selectedArea),
            onAreaSelected: _selectArea,
            searchController: _searchController,
            onSearch: _search,
            attendanceStatus: _attendanceStatus,
            onAttendanceStatusChanged: _selectAttendanceStatus,
            castSort: _castSort,
            onCastSortChanged: _selectCastSort,
          );
        },
      ),
    );
  }
}

class ResponsiveCastScreen extends StatelessWidget {
  const ResponsiveCastScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.attendanceStatus,
    required this.onAttendanceStatusChanged,
    required this.castSort,
    required this.onCastSortChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String attendanceStatus;
  final ValueChanged<String> onAttendanceStatusChanged;
  final String castSort;
  final ValueChanged<String> onCastSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = constraints.maxWidth >= 720
            ? CastDesktopScreen(
                data: data,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
                attendanceStatus: attendanceStatus,
                onAttendanceStatusChanged: onAttendanceStatusChanged,
                castSort: castSort,
                onCastSortChanged: onCastSortChanged,
              )
            : CastMobileScreen(
                data: data,
                onAreaSelected: onAreaSelected,
                searchController: searchController,
                onSearch: onSearch,
                attendanceStatus: attendanceStatus,
                onAttendanceStatusChanged: onAttendanceStatusChanged,
                castSort: castSort,
                onCastSortChanged: onCastSortChanged,
              );
        return constraints.maxWidth >= 720 ? content : SafeArea(child: content);
      },
    );
  }
}

class CastMobileScreen extends StatelessWidget {
  const CastMobileScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.attendanceStatus,
    required this.onAttendanceStatusChanged,
    required this.castSort,
    required this.onCastSortChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String attendanceStatus;
  final ValueChanged<String> onAttendanceStatusChanged;
  final String castSort;
  final ValueChanged<String> onCastSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: TopHeader(
              area: data.area,
              areaOptions: data.areaOptions,
              onAreaSelected: onAreaSelected,
              searchController: searchController,
              onSearch: onSearch,
            ),
          ),
          Positioned.fill(
            top: 116,
            bottom: 72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              children: [
                const SectionHeader(title: 'キャスト一覧', showSeeAll: false),
                const SizedBox(height: 12),
                CastStatusFilter(
                  selected: attendanceStatus,
                  onChanged: onAttendanceStatusChanged,
                ),
                const SizedBox(height: 12),
                CastResultBar(
                  count: data.casts.length,
                  selectedSort: castSort,
                  onSortChanged: onCastSortChanged,
                ),
                const SizedBox(height: 10),
                for (final cast in data.casts) ...[
                  CastListCard(
                    cast: cast,
                    onTap: () => _openCastDetail(context, cast),
                    onBook: () => _openCastShopPrice(context, cast),
                  ),
                  const SizedBox(height: 10),
                ],
                if (data.casts.isEmpty) const EmptyCastState(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              activeIndex: 2,
              onItemTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                    ),
                  );
                } else if (index == 1) {
                  _openShopPage(context, data.area);
                } else if (index == 3) {
                  _openOrderPage(context, data.area);
                } else if (index == 4) {
                  _openMyPage(context, data.area);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CastDesktopScreen extends StatelessWidget {
  const CastDesktopScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.attendanceStatus,
    required this.onAttendanceStatusChanged,
    required this.castSort,
    required this.onCastSortChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String attendanceStatus;
  final ValueChanged<String> onAttendanceStatusChanged;
  final String castSort;
  final ValueChanged<String> onCastSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DesktopHeader(
                    area: data.area,
                    areaOptions: data.areaOptions,
                    onAreaSelected: onAreaSelected,
                    searchController: searchController,
                    onSearch: onSearch,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: 'キャスト一覧',
                              showSeeAll: false,
                            ),
                            const SizedBox(height: 14),
                            CastStatusFilter(
                              selected: attendanceStatus,
                              onChanged: onAttendanceStatusChanged,
                            ),
                            const SizedBox(height: 14),
                            CastResultBar(
                              count: data.casts.length,
                              selectedSort: castSort,
                              onSortChanged: onCastSortChanged,
                            ),
                            const SizedBox(height: 14),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.casts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 380,
                                    mainAxisExtent: 156,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              itemBuilder: (_, index) => CastListCard(
                                cast: data.casts[index],
                                onTap: () =>
                                    _openCastDetail(context, data.casts[index]),
                                onBook: () => _openCastShopPrice(
                                  context,
                                  data.casts[index],
                                ),
                              ),
                            ),
                            if (data.casts.isEmpty) const EmptyCastState(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CastStatusFilter extends StatelessWidget {
  const CastStatusFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  static const options = <(String, String)>[
    ('', 'すべて'),
    ('working', '出勤中'),
    ('scheduled', '出勤予定'),
    ('off', '休み'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in options) ...[
              _CastStatusButton(
                label: option.$2,
                selected: selected == option.$1,
                onTap: () => onChanged(option.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CastStatusButton extends StatelessWidget {
  const _CastStatusButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD4AE62) : const Color(0xFF151514),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE7C982)
                  : const Color(0xFF3A3328),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF1A1308)
                  : const Color(0xFFBEBAB3),
            ),
          ),
        ),
      ),
    );
  }
}

class CastResultBar extends StatelessWidget {
  const CastResultBar({
    super.key,
    required this.count,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final int count;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count名',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC7C7CA),
          ),
        ),
        const Spacer(),
        const Icon(Icons.sort_rounded, size: 15, color: Color(0xFFD7B56D)),
        const SizedBox(width: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSort,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFFD7B56D),
            ),
            dropdownColor: const Color(0xFF211E19),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD7B56D),
            ),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
            items: const [
              DropdownMenuItem(value: 'recommended', child: Text('おすすめ順')),
              DropdownMenuItem(value: 'popular', child: Text('人気順')),
              DropdownMenuItem(value: 'rating', child: Text('評価順')),
              DropdownMenuItem(value: 'updated', child: Text('更新順')),
            ],
          ),
        ),
      ],
    );
  }
}

class CastListCard extends StatelessWidget {
  const CastListCard({super.key, required this.cast, this.onTap, this.onBook});

  final CastData cast;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 156,
        decoration: BoxDecoration(
          color: const Color(0xFF151514),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFF2A261F)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            CastListImage(cast: cast),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cast.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x2026B35A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            cast.badge,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Color(cast.color),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cast.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 17,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final tag in cast.tags) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1AD7B56D),
                                      border: Border.all(
                                        color: const Color(0x66D7B56D),
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Color(0xFFD7B56D),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    CastShopMiniCard(
                      shopName: cast.shop.isNotEmpty ? cast.shop : cast.area,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFFD7B56D),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            cast.area,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB7B7BA),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Text(
                          '★',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF1D084),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cast.rating.isNotEmpty ? cast.rating : '4.8',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF1D084),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 74,
                          child: GoldButton(
                            height: 22,
                            fontSize: 9,
                            onTap: onBook,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CastListImage extends StatelessWidget {
  const CastListImage({super.key, required this.cast});

  final CastData cast;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        cast.asset.startsWith('http://') || cast.asset.startsWith('https://');
    final fallback = Image.asset(
      cast.fallbackAsset,
      width: 116,
      height: double.infinity,
      fit: BoxFit.cover,
    );
    if (!isNetwork) {
      return Image.asset(
        cast.asset,
        width: 116,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      cast.asset,
      width: 116,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

class EmptyCastState extends StatelessWidget {
  const EmptyCastState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Text(
          '該当するキャストがありません',
          style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9F)),
        ),
      ),
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.api, this.initialArea = '東京都'});

  final HomeApi api;
  final String initialArea;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late String _selectedArea = widget.initialArea;
  String _keyword = '';
  String _sort = 'recommended';
  String _shopFilter = '';
  late final TextEditingController _searchController = TextEditingController();
  late Future<HomeViewData> _shopData = widget.api.fetchHome(
    area: widget.initialArea,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectArea(String area) {
    if (area == _selectedArea) return;
    setState(() {
      _selectedArea = area;
      AppSession.currentArea = area;
      _shopData = widget.api.fetchHome(
        area: area,
        keyword: _keyword,
        sort: _sort,
        shopFilter: _shopFilter,
      );
    });
  }

  void _search(String keyword) {
    final nextKeyword = keyword.trim();
    if (nextKeyword == _keyword) return;
    setState(() {
      _keyword = nextKeyword;
      _shopData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        sort: _sort,
        shopFilter: _shopFilter,
      );
    });
  }

  void _changeShopFilter(String filter) {
    if (filter == _shopFilter) return;
    setState(() {
      _shopFilter = filter;
      _shopData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        sort: _sort,
        shopFilter: filter,
      );
    });
  }

  void _changeSort(String sort) {
    if (sort == _sort) return;
    setState(() {
      _sort = sort;
      _shopData = widget.api.fetchHome(
        area: _selectedArea,
        keyword: _keyword,
        sort: sort,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<HomeViewData>(
        future: _shopData,
        builder: (context, snapshot) {
          return ResponsiveShopScreen(
            data:
                snapshot.data ??
                HomeViewData.empty(selectedArea: _selectedArea),
            onAreaSelected: _selectArea,
            searchController: _searchController,
            onSearch: _search,
            selectedSort: _sort,
            onSortChanged: _changeSort,
            selectedFilter: _shopFilter,
            onFilterChanged: _changeShopFilter,
          );
        },
      ),
    );
  }
}

class ResponsiveShopScreen extends StatelessWidget {
  const ResponsiveShopScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.selectedSort,
    required this.onSortChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return ShopDesktopScreen(
            data: data,
            onAreaSelected: onAreaSelected,
            searchController: searchController,
            onSearch: onSearch,
            selectedSort: selectedSort,
            onSortChanged: onSortChanged,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
          );
        }
        return SafeArea(
          child: ShopMobileScreen(
            data: data,
            onAreaSelected: onAreaSelected,
            searchController: searchController,
            onSearch: onSearch,
            selectedSort: selectedSort,
            onSortChanged: onSortChanged,
            selectedFilter: selectedFilter,
            onFilterChanged: onFilterChanged,
          ),
        );
      },
    );
  }
}

class ShopMobileScreen extends StatelessWidget {
  const ShopMobileScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.selectedSort,
    required this.onSortChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: TopHeader(
              area: data.area,
              areaOptions: data.areaOptions,
              onAreaSelected: onAreaSelected,
              searchController: searchController,
              onSearch: onSearch,
            ),
          ),
          Positioned.fill(
            top: 116,
            bottom: 72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
              children: [
                const SectionHeader(title: 'ショップ一覧', showSeeAll: false),
                const SizedBox(height: 12),
                ShopFilterBar(
                  selectedFilter: selectedFilter,
                  onChanged: onFilterChanged,
                ),
                const SizedBox(height: 10),
                ShopResultBar(
                  count: data.shops.length,
                  selectedSort: selectedSort,
                  onSortChanged: onSortChanged,
                ),
                const SizedBox(height: 10),
                if (data.shops.any((shop) => shop.isSearchFallback))
                  const ShopSearchFallbackNotice(),
                for (final shop in data.shops) ...[
                  ShopListCard(
                    shop: shop,
                    onTap: () => _openShopDetail(context, shop),
                    onBook: () => _openShopDetailAtTab(context, shop, 1),
                  ),
                  const SizedBox(height: 10),
                ],
                if (data.shops.isEmpty) const EmptyShopState(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FooterNavigation(
              activeIndex: 1,
              onItemTap: (index) {
                if (index == 0) {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder<void>(
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                      pageBuilder: (_, _, _) => HomePage(api: HomeApi()),
                    ),
                  );
                } else if (index == 2) {
                  _openCastPage(context, data.area);
                } else if (index == 3) {
                  _openOrderPage(context, data.area);
                } else if (index == 4) {
                  _openMyPage(context, data.area);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShopDesktopScreen extends StatelessWidget {
  const ShopDesktopScreen({
    super.key,
    required this.data,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    required this.selectedSort,
    required this.onSortChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final HomeViewData data;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          const Positioned.fill(child: HomeGlow()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DesktopHeader(
                    area: data.area,
                    areaOptions: data.areaOptions,
                    onAreaSelected: onAreaSelected,
                    searchController: searchController,
                    onSearch: onSearch,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: 'ショップ一覧',
                              showSeeAll: false,
                            ),
                            const SizedBox(height: 14),
                            ShopFilterBar(
                              selectedFilter: selectedFilter,
                              onChanged: onFilterChanged,
                            ),
                            const SizedBox(height: 12),
                            ShopResultBar(
                              count: data.shops.length,
                              selectedSort: selectedSort,
                              onSortChanged: onSortChanged,
                            ),
                            const SizedBox(height: 14),
                            if (data.shops.any((shop) => shop.isSearchFallback))
                              const ShopSearchFallbackNotice(),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.shops.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 520,
                                    mainAxisExtent: 148,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                              itemBuilder: (_, index) => ShopListCard(
                                shop: data.shops[index],
                                onTap: () =>
                                    _openShopDetail(context, data.shops[index]),
                                onBook: () => _openShopDetailAtTab(
                                  context,
                                  data.shops[index],
                                  1,
                                ),
                              ),
                            ),
                            if (data.shops.isEmpty) const EmptyShopState(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShopFilterBar extends StatelessWidget {
  const ShopFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = <(String, String)>[
      ('', 'すべて'),
      ('open', '営業中'),
      ('booking', '予約可'),
      ('discount', '割引あり'),
    ];
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in filters) ...[
              _CastStatusButton(
                label: filter.$2,
                selected: selectedFilter == filter.$1,
                onTap: () => onChanged(filter.$1),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class ShopResultBar extends StatelessWidget {
  const ShopResultBar({
    super.key,
    required this.count,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final int count;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$count店舗',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC7C7CA),
          ),
        ),
        const Spacer(),
        const Icon(Icons.sort_rounded, size: 15, color: Color(0xFFD7B56D)),
        const SizedBox(width: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedSort,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFFD7B56D),
            ),
            dropdownColor: const Color(0xFF211E19),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD7B56D),
            ),
            onChanged: (value) {
              if (value != null) onSortChanged(value);
            },
            items: const [
              DropdownMenuItem(value: 'recommended', child: Text('おすすめ順')),
              DropdownMenuItem(value: 'popular', child: Text('人気順')),
              DropdownMenuItem(value: 'distance', child: Text('距離順')),
              DropdownMenuItem(value: 'rating', child: Text('評価順')),
              DropdownMenuItem(value: 'updated', child: Text('更新順')),
            ],
          ),
        ),
      ],
    );
  }
}

class ShopSearchFallbackNotice extends StatelessWidget {
  const ShopSearchFallbackNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(
        '該当する店舗が見つかりませんでした。おすすめの店舗を表示します。',
        style: TextStyle(fontSize: 11, color: Color(0xFFBDBDC2)),
      ),
    );
  }
}

class ShopListCard extends StatelessWidget {
  const ShopListCard({super.key, required this.shop, this.onTap, this.onBook});

  final ShopData shop;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${shop.name} 店舗詳細',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            color: const Color(0xFF151514),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFF2A261F)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              ShopListImage(shop: shop),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: shop.businessStatus == '営業中'
                                  ? const Color(0x2026B35A)
                                  : const Color(0x20A7A7AA),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              shop.businessStatus,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: shop.businessStatus == '営業中'
                                    ? const Color(0xFF7AD95F)
                                    : const Color(0xFFB7B7BA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Color(0xFFD7B56D),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              shop.area,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB7B7BA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        shop.price.isNotEmpty ? shop.price : '料金は店舗ページで確認',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBDBDBF),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text(
                            '★',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF1D084),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shop.score,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF1D084),
                            ),
                          ),
                          if (shop.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shop.tags.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFFB7B7BA),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 74,
                            child: GoldButton(
                              height: 22,
                              fontSize: 9,
                              onTap: onBook,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopListImage extends StatelessWidget {
  const ShopListImage({super.key, required this.shop});

  final ShopData shop;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        shop.asset.startsWith('http://') || shop.asset.startsWith('https://');
    final fallback = Image.asset(
      shop.fallbackAsset,
      width: 116,
      height: double.infinity,
      fit: BoxFit.cover,
    );
    if (!isNetwork) {
      return Image.asset(
        shop.asset,
        width: 116,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      shop.asset,
      width: 116,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

class EmptyShopState extends StatelessWidget {
  const EmptyShopState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Text(
          '該当する店舗がありません',
          style: TextStyle(fontSize: 13, color: Color(0xFF9B9B9F)),
        ),
      ),
    );
  }
}

class ShopDetailPage extends StatefulWidget {
  const ShopDetailPage({super.key, required this.shop, this.initialTab = 0});

  final ShopData shop;
  final int initialTab;

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  late int _selectedTab = widget.initialTab.clamp(0, 3);
  String _castFilter = '';
  bool _isFavorite = false;
  bool _favoriteLoading = false;
  late final Future<ShopDetailData?> _detailFuture = _loadDetail();

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    if (!AppSession.isAuthenticated || widget.shop.id <= 0) return;
    try {
      final favorited = await FavoriteApi().fetchStatus(
        token: AppSession.token,
        shopId: widget.shop.id,
      );
      if (mounted) setState(() => _isFavorite = favorited);
    } catch (_) {
      // The detail page remains usable when the favorite endpoint is unavailable.
    }
  }

  Future<void> _toggleFavorite() async {
    if (!AppSession.isAuthenticated) {
      _showMessage('お気に入り登録にはログインが必要です');
      return;
    }
    if (_favoriteLoading) return;
    setState(() => _favoriteLoading = true);
    try {
      final favorited = await FavoriteApi().toggle(
        token: AppSession.token,
        shopId: widget.shop.id,
      );
      if (!mounted) return;
      setState(() => _isFavorite = favorited);
      _showMessage(favorited ? 'お気に入り店舗に追加しました' : 'お気に入り店舗から削除しました');
    } catch (_) {
      if (mounted) _showMessage('お気に入りを更新できませんでした');
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  Future<ShopDetailData?> _loadDetail() async {
    final api = HomeApi();
    final detail = await api.fetchShopDetail(widget.shop.id);
    if (detail == null || detail.casts.isNotEmpty) return detail;

    final areaData = await api.fetchHome(area: widget.shop.area);
    final shopCasts = areaData.casts
        .where(
          (cast) =>
              cast.shopId == widget.shop.id ||
              cast.shop.trim() == widget.shop.name.trim(),
        )
        .toList();
    return shopCasts.isEmpty ? detail : detail.copyWith(casts: shopCasts);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopDetailData?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final shop = detail == null ? widget.shop : _shopFromDetail(detail);
        return _buildDetail(context, shop);
      },
    );
  }

  ShopData _shopFromDetail(ShopDetailData detail) => ShopData(
    id: detail.id,
    name: detail.name,
    area: detail.area,
    description: detail.description,
    address: detail.address,
    station: detail.station,
    isRecommended: widget.shop.isRecommended,
    businessStatus: detail.businessStatus == '営業中' ? '営業中' : '休み',
    businessHours: detail.businessHours,
    bookingEnabled: detail.bookingEnabled,
    shopImages: detail.images,
    packageSets: detail.packageSets,
    casts: detail.casts,
    reviews: detail.reviews,
    price: detail.priceRange,
    score: detail.rating,
    count: detail.reviewCount > 0 ? '(${detail.reviewCount})' : '',
    tags: widget.shop.tags,
    asset: detail.images.isNotEmpty ? detail.images.first : widget.shop.asset,
    fallbackAsset: widget.shop.fallbackAsset,
    rank: widget.shop.rank,
    ribbonColor: widget.shop.ribbonColor,
    isSearchFallback: false,
  );

  Widget _buildDetail(BuildContext context, ShopData activeShop) {
    if (MediaQuery.sizeOf(context).width > 0) {
      return _ReferenceShopDetailLayout(
        shop: activeShop,
        casts: activeShop.casts,
        reviews: activeShop.reviews,
        selectedTab: _selectedTab,
        castFilter: _castFilter,
        onTabChanged: (value) => setState(() => _selectedTab = value),
        onCastFilterChanged: (value) => setState(() => _castFilter = value),
        onBack: () => Navigator.of(context).pop(),
        onMessage: _showMessage,
        isFavorite: _isFavorite,
        onFavorite: _toggleFavorite,
      );
    }

    final shop = activeShop;
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ShopDetailHeader(
                    onBack: () => Navigator.of(context).pop(),
                    isFavorite: _isFavorite,
                    onFavorite: _toggleFavorite,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _ShopHero(shop: shop),
                        const SizedBox(height: 14),
                        _ShopQuickActions(
                          price: shop.price,
                          businessHours: shop.businessHours,
                          bookingEnabled: shop.bookingEnabled,
                        ),
                        const SizedBox(height: 14),
                        _ShopDetailTabs(
                          selectedIndex: _selectedTab,
                          onChanged: (index) =>
                              setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: 20),
                        if (_selectedTab == 2)
                          _ShopCastSection(
                            casts: shop.casts,
                            filter: _castFilter,
                            onFilterChanged: (value) =>
                                setState(() => _castFilter = value),
                          )
                        else
                          _ShopInfoSection(
                            tabIndex: _selectedTab,
                            price: shop.price,
                            description: shop.description,
                            shopName: shop.name,
                            address: shop.address,
                            station: shop.station,
                            businessHours: shop.businessHours,
                            shopImages: shop.shopImages,
                            packageSets: shop.packageSets,
                            casts: shop.casts,
                            reviews: shop.reviews,
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FooterNavigation(
                activeIndex: 1,
                onItemTap: (index) => _handleDetailFooterNavigation(
                  context,
                  index,
                  widget.shop.area,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceShopDetailLayout extends StatelessWidget {
  const _ReferenceShopDetailLayout({
    required this.shop,
    required this.casts,
    required this.reviews,
    required this.selectedTab,
    required this.castFilter,
    required this.onTabChanged,
    required this.onCastFilterChanged,
    required this.onBack,
    required this.onMessage,
    required this.isFavorite,
    required this.onFavorite,
  });

  final ShopData shop;
  final List<CastData> casts;
  final List<Map<String, dynamic>> reviews;
  final int selectedTab;
  final String castFilter;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<String> onCastFilterChanged;
  final VoidCallback onBack;
  final ValueChanged<String> onMessage;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth.clamp(320.0, 430.0);
            return Center(
              child: SizedBox(
                width: canvasWidth,
                child: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ShopDetailHeader(
                            onBack: onBack,
                            isFavorite: isFavorite,
                            onFavorite: onFavorite,
                            onShare: () => onMessage('共有機能は準備中です'),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 86),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                _ShopHero(shop: shop),
                                const SizedBox(height: 8),
                                _ShopQuickActions(
                                  price: shop.price,
                                  businessHours: shop.businessHours,
                                  bookingEnabled: shop.bookingEnabled,
                                ),
                                const SizedBox(height: 8),
                                _ShopDetailTabs(
                                  selectedIndex: selectedTab,
                                  onChanged: onTabChanged,
                                ),
                                const SizedBox(height: 12),
                                if (selectedTab == 2)
                                  _ShopCastSection(
                                    casts: casts,
                                    filter: castFilter,
                                    onFilterChanged: onCastFilterChanged,
                                  )
                                else
                                  _ShopInfoSection(
                                    tabIndex: selectedTab,
                                    price: shop.price,
                                    description: shop.description,
                                    shopName: shop.name,
                                    address: shop.address,
                                    station: shop.station,
                                    businessHours: shop.businessHours,
                                    shopImages: shop.shopImages,
                                    packageSets: shop.packageSets,
                                    casts: shop.casts,
                                    reviews: shop.reviews,
                                  ),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: FooterNavigation(
                        activeIndex: 1,
                        onItemTap: (index) => _handleDetailFooterNavigation(
                          context,
                          index,
                          shop.area,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShopDetailHeader extends StatelessWidget {
  const _ShopDetailHeader({
    required this.onBack,
    this.isFavorite = false,
    this.onFavorite,
    this.onShare,
  });

  final VoidCallback onBack;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              '店舗詳細',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF0C96D),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              tooltip: '戻る',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: Color(0xFFE2B85F),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onFavorite,
                  tooltip: 'お気に入り',
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 24,
                    color: isFavorite
                        ? const Color(0xFFD7B56D)
                        : const Color(0xFFE2B85F),
                  ),
                ),
                IconButton(
                  onPressed: onShare,
                  tooltip: '共有',
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: Color(0xFFE2B85F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.shop});

  final ShopData shop;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width > 0) {
      return _ShopHeroReference(shop: shop);
    }

    return AspectRatio(
      aspectRatio: 2,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF11100E),
          border: Border.all(color: const Color(0xFFB6812D)),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final image = shop.asset.startsWith('http')
                ? Image.network(
                    shop.asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Image.asset(shop.fallbackAsset, fit: BoxFit.cover),
                  )
                : Image.asset(shop.asset, fit: BoxFit.cover);
            final compact = constraints.maxWidth < 420;
            return Stack(
              fit: StackFit.expand,
              children: [
                image,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        const Color(0xF5050505),
                        Colors.black.withAlpha(175),
                        Colors.black.withAlpha(20),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: compact
                      ? constraints.maxWidth * 0.82
                      : constraints.maxWidth * 0.62,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 14 : 22, 24, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shop.name.isEmpty
                              ? 'LUXE TOKYO'
                              : shop.name.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 22 : 25,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF1D084),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 7,
                          children: [
                            _DetailPill(
                              icon: Icons.location_on,
                              text: shop.area.isEmpty ? '新宿・歌舞伎町' : shop.area,
                            ),
                            const _DetailPill(
                              icon: Icons.calendar_month,
                              text: '本日予約可',
                              accent: true,
                            ),
                            _StatusPill(status: shop.businessStatus),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF1D084),
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shop.score.isEmpty ? '4.9' : shop.score,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF1D084),
                              ),
                            ),
                            const _DetailDivider(),
                            Flexible(
                              child: Text(
                                shop.count.isEmpty
                                    ? '256件'
                                    : shop.count
                                          .replaceAll('(', '')
                                          .replaceAll(')', ''),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFBDBDC2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(0xFFD7B56D),
                              size: 19,
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                shop.station.isEmpty ? '最寄駅未設定' : shop.station,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFBDBDC2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShopHeroReference extends StatelessWidget {
  const _ShopHeroReference({required this.shop});

  final ShopData shop;

  @override
  Widget build(BuildContext context) {
    final shopName = shop.name.isEmpty ? 'LUXE TOKYO' : shop.name.toUpperCase();
    final area = shop.area.isEmpty ? '新宿・歌舞伎町' : shop.area;
    final score = shop.score.isEmpty ? '4.8' : shop.score;
    final reviewCount = shop.count.isEmpty
        ? '口コミ'
        : '${shop.count.replaceAll('(', '').replaceAll(')', '')}件';
    final image = shop.asset.startsWith('http')
        ? Image.network(
            shop.asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset(shop.fallbackAsset, fit: BoxFit.cover),
          )
        : Image.asset(shop.asset, fit: BoxFit.cover);
    return AspectRatio(
      aspectRatio: 2.5,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0C0B),
          border: Border.all(color: const Color(0xFFB6812D)),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(flex: 43, child: SizedBox.expand(child: image)),
            Expanded(
              flex: 57,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 210,
                    height: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF1D084),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            _DetailPill(icon: Icons.location_on, text: area),
                            const _DetailPill(
                              icon: Icons.calendar_month,
                              text: '本日予約可',
                              accent: true,
                            ),
                            _StatusPill(status: shop.businessStatus),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF1D084),
                              size: 18,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              score,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF1D084),
                              ),
                            ),
                            const _DetailDivider(),
                            Flexible(
                              child: Text(
                                reviewCount,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFBDBDC2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Color(0xFFD7B56D),
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.station.isEmpty ? '最寄駅未設定' : shop.station,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFBDBDC2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.text,
    this.accent = false,
  });
  final IconData icon;
  final String text;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFF9C702D)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFFE3B961)),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: accent ? const Color(0xFFF1D084) : const Color(0xFFD2D2D4),
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == '営業中';
    final color = isOpen ? const Color(0xFF79D957) : const Color(0xFFE46B69);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(190)),
        borderRadius: BorderRadius.circular(18),
        color: color.withAlpha(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.circle : Icons.pause_circle_outline,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 23,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: const Color(0xFF65605B),
  );
}

String _startingPrice(String value) {
  final match = RegExp(r'\d[\d,]*').firstMatch(value);
  if (match == null) return value.isEmpty ? '料金は店舗ページで確認' : value;

  final digits = match.group(0)!.replaceAll(',', '');
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[index]);
  }
  return '¥$grouped〜';
}

class _ShopQuickActions extends StatelessWidget {
  const _ShopQuickActions({
    required this.price,
    required this.businessHours,
    required this.bookingEnabled,
  });

  final String price;
  final String businessHours;
  final bool bookingEnabled;

  @override
  Widget build(BuildContext context) {
    return _ShopQuickActionsReference(
      price: price,
      businessHours: businessHours,
      bookingEnabled: bookingEnabled,
    );
  }
}

class _ShopQuickActionsReference extends StatelessWidget {
  const _ShopQuickActionsReference({
    required this.price,
    required this.businessHours,
    required this.bookingEnabled,
  });

  final String price;
  final String businessHours;
  final bool bookingEnabled;

  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFFC08B36)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 350,
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: _QuickStatBar(
                icon: Icons.currency_yen_rounded,
                label: '料金',
                value: _startingPrice(price),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickStatBar(
                icon: Icons.schedule_rounded,
                label: '営業時間',
                value: businessHours.isEmpty ? '営業時間は店舗ページで確認' : businessHours,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _QuickStatBar(
                icon: Icons.timer_outlined,
                label: '予約受付',
                value: bookingEnabled ? '受付中' : '停止中',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /*
  Widget buildLegacy(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stats = Row(
        children: [
          const Expanded(
            child: _QuickStat(
              icon: Icons.currency_yen_rounded,
              label: '料金',
              value: '¥6,000〜',
            ),
          ),
          const _QuickDivider(),
          const Expanded(
            child: _QuickStat(
              icon: Icons.schedule_rounded,
              label: '営業時間',
              value: '20:00〜LAST',
            ),
          ),
          const _QuickDivider(),
          const Expanded(
            child: _QuickStat(
              icon: Icons.timer_outlined,
              label: '最短',
              value: '21:00〜',
            ),
          ),
        ],
      );

      return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF11100F),
          border: Border.all(color: const Color(0xFFC08B36)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: constraints.maxWidth < 560
            ? Column(
                children: [
                  SizedBox(height: 64, child: stats),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: _GoldActionButton(label: '今すぐ予約', onTap: onBook),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: stats),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 126,
                    height: 55,
                    child: _GoldActionButton(label: '今すぐ予約', onTap: onBook),
                  ),
                ],
              ),
      );
    },
  );
  */
}

class _QuickStatBar extends StatelessWidget {
  const _QuickStatBar({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFFC08B36)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 104,
        height: 52,
        child: _QuickStat(icon: icon, label: label, value: value),
      ),
    ),
  );
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFFF1D084)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDC2)),
          ),
        ],
      ),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFF1D084),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _ShopDetailTabs extends StatelessWidget {
  const _ShopDetailTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFF775722)),
      borderRadius: BorderRadius.circular(36),
    ),
    child: Row(
      children: [
        _tab('店舗情報', 0),
        _tab('料金', 1),
        _tab('キャスト', 2),
        _tab('口コミ', 3),
      ],
    ),
  );
  Widget _tab(String label, int index) => Expanded(
    child: GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? const Color(0xFFE7BD6B)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1,
            color: selectedIndex == index
                ? const Color(0xFF2B2113)
                : const Color(0xFFBDBDC2),
            fontWeight: selectedIndex == index
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _ShopCastSection extends StatelessWidget {
  const _ShopCastSection({
    required this.casts,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<CastData> casts;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  @override
  Widget build(BuildContext context) {
    final visibleCasts = switch (filter) {
      '' => casts,
      'working' => casts.where((cast) => cast.badge == '出勤中').toList(),
      'scheduled' =>
        casts
            .where((cast) => cast.badge != '出勤中' && cast.badge != '休み')
            .toList(),
      'off' => casts.where((cast) => cast.badge == '休み').toList(),
      _ => casts,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '本日の出勤',
              style: TextStyle(
                fontSize: 19,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${visibleCasts.length}名出勤予定',
              style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDC2)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CastFilters(selected: filter, onChanged: onFilterChanged),
        const SizedBox(height: 14),
        if (visibleCasts.isEmpty)
          const EmptyCastState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCasts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) => CastListCard(
              cast: visibleCasts[index],
              onTap: () => _openCastDetail(context, visibleCasts[index]),
              onBook: () => _openCastShopPrice(context, visibleCasts[index]),
            ),
          ),
      ],
    );
  }
}

class _CastFilters extends StatelessWidget {
  const _CastFilters({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) =>
      CastStatusFilter(selected: selected, onChanged: onChanged);
}

class _ShopInfoSection extends StatelessWidget {
  const _ShopInfoSection({
    required this.tabIndex,
    required this.price,
    required this.description,
    required this.shopName,
    required this.address,
    required this.station,
    required this.businessHours,
    required this.shopImages,
    required this.packageSets,
    required this.casts,
    required this.reviews,
  });
  final int tabIndex;
  final String price;
  final String description;
  final String shopName;
  final String address;
  final String station;
  final String businessHours;
  final List<String> shopImages;
  final List<Map<String, dynamic>> packageSets;
  final List<CastData> casts;
  final List<Map<String, dynamic>> reviews;
  @override
  Widget build(BuildContext context) {
    final titles = ['店舗説明', '料金表', '', '口コミ'];
    if (tabIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShopDescriptionBox(description: description),
          SizedBox(height: 16),
          _ShopDetailPhoto(images: shopImages),
          SizedBox(height: 16),
          _ShopDetailFacts(
            address: address,
            station: station,
            businessHours: businessHours,
          ),
          SizedBox(height: 16),
          _ShopDetailPlans(
            plans: packageSets,
            shopName: shopName,
            shopImage: shopImages.isNotEmpty ? shopImages.first : '',
            castNames: casts.map((cast) => cast.name).toList(),
            recommendedOnly: true,
          ),
          SizedBox(height: 16),
          _ShopDetailPopularCasts(casts: casts),
        ],
      );
    }
    if (tabIndex == 1) {
      return _ShopPriceSection(
        price: price,
        plans: packageSets,
        shopName: shopName,
        shopImage: shopImages.isNotEmpty ? shopImages.first : '',
        castNames: casts.map((cast) => cast.name).toList(),
      );
    }
    if (tabIndex == 3) {
      return _ShopReviewSection(reviews: reviews);
    }
    final body = tabIndex == 0
        ? const Text('')
        : tabIndex == 1
        ? const Column(
            children: [
              _PriceInfoRow(label: '基本料金', value: '¥6,000〜'),
              _PriceInfoDivider(),
              _PriceInfoRow(label: '延長料金', value: '30分 ¥3,000〜'),
              _PriceInfoDivider(),
              _PriceInfoRow(label: '指名料', value: '¥2,000〜'),
            ],
          )
        : const Text(
            'まだ口コミはありません。',
            style: TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFFD0D0D2),
            ),
          );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF11100F),
        border: Border.all(color: const Color(0xFF6B4D20)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1713),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Text(
              titles[tabIndex],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: body),
        ],
      ),
    );
  }
}

class _ShopPriceSection extends StatelessWidget {
  const _ShopPriceSection({
    required this.price,
    required this.plans,
    required this.shopName,
    required this.shopImage,
    required this.castNames,
  });

  final String price;
  final List<Map<String, dynamic>> plans;
  final String shopName;
  final String shopImage;
  final List<String> castNames;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ShopSectionBox(
        title: '料金表',
        child: Column(
          children: [
            _PriceInfoRow(label: '基本料金', value: _startingPrice(price)),
            _PriceInfoDivider(),
            _PriceInfoRow(label: '延長料金', value: '30分 ¥3,000〜'),
            _PriceInfoDivider(),
            _PriceInfoRow(label: '指名料', value: '¥2,000〜'),
          ],
        ),
      ),
      SizedBox(height: 16),
      _ShopDetailPlans(
        title: 'セットプラン',
        plans: plans,
        shopName: shopName,
        shopImage: shopImage,
        castNames: castNames,
      ),
    ],
  );
}

class _ShopReviewSection extends StatelessWidget {
  const _ShopReviewSection({required this.reviews});

  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Text(
          'まだ口コミはありません。',
          style: TextStyle(fontSize: 14, height: 1.8, color: Color(0xFFD0D0D2)),
        ),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < reviews.length; index++) ...[
          _ShopReviewCard(
            name: '${reviews[index]['name'] ?? ''}',
            date: '${reviews[index]['date'] ?? ''}',
            rating: '${reviews[index]['rating'] ?? ''}',
            content: '${reviews[index]['content'] ?? ''}',
          ),
          if (index < reviews.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ShopReviewCard extends StatelessWidget {
  const _ShopReviewCard({
    required this.name,
    required this.date,
    required this.rating,
    required this.content,
  });

  final String name;
  final String date;
  final String rating;
  final String content;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFF6B4D20)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2115),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: Color(0xFFF1D084),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              date,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8F8B86)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              '★★★★★',
              style: TextStyle(fontSize: 13, color: Color(0xFFF1D084)),
            ),
            const SizedBox(width: 7),
            Text(
              rating,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            height: 1.7,
            color: Color(0xFFD0D0D2),
          ),
        ),
      ],
    ),
  );
}

class _ShopSectionBox extends StatelessWidget {
  const _ShopSectionBox({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFF6B4D20)),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1A1713),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFF1D084),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.all(18), child: child),
      ],
    ),
  );
}

class _ShopDescriptionBox extends StatelessWidget {
  const _ShopDescriptionBox({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFF11100F),
      border: Border.all(color: const Color(0xFF6B4D20)),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            '店舗説明',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFF1D084),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            description.isEmpty ? '店舗説明は準備中です。' : description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
              color: Color(0xFFD0D0D2),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShopDetailFacts extends StatelessWidget {
  const _ShopDetailFacts({
    required this.address,
    required this.station,
    required this.businessHours,
  });

  final String address;
  final String station;
  final String businessHours;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF0D0C0B),
      border: Border.all(color: const Color(0xFF6B4D20)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        _ShopDetailFactRow(
          icon: Icons.location_on_outlined,
          label: '店舗住所',
          value: address.isEmpty ? '住所未設定' : address,
        ),
        _ShopDetailFactDivider(),
        _ShopDetailFactRow(
          icon: Icons.schedule_outlined,
          label: '営業時間',
          value: businessHours.isEmpty ? '営業時間未設定' : businessHours,
        ),
        _ShopDetailFactDivider(),
        _ShopDetailFactRow(
          icon: Icons.train_outlined,
          label: '最寄駅',
          value: station.isEmpty ? '最寄駅未設定' : station,
        ),
      ],
    ),
  );
}

class _ShopDetailFactRow extends StatelessWidget {
  const _ShopDetailFactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFFF1D084)),
              const SizedBox(width: 7),
              Padding(
                padding: EdgeInsets.only(left: label == '最寄駅' ? 2 : 0),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFF1D084),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFFD0D0D2)),
          ),
        ),
      ],
    ),
  );
}

class _ShopDetailFactDivider extends StatelessWidget {
  const _ShopDetailFactDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFF625D56));
}

class _ShopDetailPhoto extends StatelessWidget {
  const _ShopDetailPhoto({required this.images});

  final List<String> images;

  static const photos = [
    'assets/home/shop-luxe-tokyo-cover-v1.png',
    'assets/home/shop-aile-cover-v1.png',
    'assets/home/shop-venus-cover-v1.png',
    'assets/home/shop-luxe-tokyo-cover-v1.png',
  ];

  List<String> get displayPhotos => images.isEmpty ? photos : images;

  Widget _photoImage(String path) => path.startsWith('http')
      ? Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Image.asset(photos.first, fit: BoxFit.cover),
        )
      : Image.asset(path, fit: BoxFit.cover);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '店舗写真',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayPhotos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showFullscreenPhoto(context, index, displayPhotos),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _photoImage(displayPhotos[index]),
          ),
        ),
      ),
    ],
  );

  static void _showFullscreenPhoto(
    BuildContext context,
    int initialIndex,
    List<String> photoList,
  ) {
    var currentIndex = initialIndex;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: photoList[currentIndex].startsWith('http')
                      ? Image.network(
                          photoList[currentIndex],
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          photoList[currentIndex],
                          fit: BoxFit.contain,
                        ),
                ),
                Positioned(
                  left: 0,
                  child: _PhotoPreviewButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: currentIndex == 0
                        ? null
                        : () => setDialogState(() => currentIndex--),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: _PhotoPreviewButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: currentIndex == photoList.length - 1
                        ? null
                        : () => setDialogState(() => currentIndex++),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    tooltip: '閉じる',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhotoPreviewButton extends StatelessWidget {
  const _PhotoPreviewButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: onTap == null ? Colors.white24 : Colors.white,
      tooltip: icon == Icons.chevron_left_rounded ? '上一张' : '下一张',
    ),
  );
}

class _ShopDetailPlans extends StatelessWidget {
  const _ShopDetailPlans({
    required this.plans,
    required this.shopName,
    required this.shopImage,
    required this.castNames,
    this.title = 'おすすめプラン',
    this.recommendedOnly = false,
  });

  final List<Map<String, dynamic>> plans;
  final String shopName;
  final String shopImage;
  final List<String> castNames;
  final String title;
  final bool recommendedOnly;

  int _amount(Object? value) =>
      int.tryParse('${value ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formattedAmount(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  String _salePrice(Map<String, dynamic> plan, int original) {
    final sale = _amount(plan['sale_price']);
    if (sale > 0) return _formattedAmount(sale);
    final discount = _amount(plan['discount_value']);
    final type = '${plan['discount_type'] ?? ''}';
    final discounted = type == 'amount'
        ? original - discount
        : type == 'percent' || type == 'percentage'
        ? original - ((original * discount) / 100).floor()
        : original;
    return _formattedAmount(discounted > 0 ? discounted : original);
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlans = recommendedOnly
        ? plans
              .where(
                (plan) =>
                    plan['is_recommended'] == true ||
                    plan['is_recommended'] == 1 ||
                    plan['is_recommended'] == '1',
              )
              .toList()
        : plans;
    if (visiblePlans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final plan in visiblePlans) ...[
          Builder(
            builder: (context) {
              final planImage = _resolvePlanImageUrl(
                (plan['image'] ?? '').toString(),
              );
              final image = planImage.isEmpty
                  ? const Icon(
                      Icons.local_bar_outlined,
                      size: 28,
                      color: Color(0xFFF1D084),
                    )
                  : planImage.startsWith('http')
                  ? Image.network(
                      planImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.local_bar_outlined,
                        size: 28,
                        color: Color(0xFFF1D084),
                      ),
                    )
                  : Image.asset(planImage, fit: BoxFit.cover);
              final planTags = plan['tags'] is List
                  ? (plan['tags'] as List)
                        .map((tag) => tag.toString().trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList()
                  : <String>[];
              final originalAmount = _amount(plan['price']);
              final originalPrice = _formattedAmount(originalAmount);
              final salePrice = _salePrice(plan, originalAmount);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF11100F),
                  border: Border.all(color: const Color(0xFF6B4D20)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2115),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: image,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan['name'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${plan['description'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFBDBDC2),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '¥$salePrice',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFF1D084),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (originalPrice.isNotEmpty &&
                                  originalPrice != salePrice) ...[
                                const SizedBox(width: 5),
                                Text(
                                  '通常 ¥$originalPrice',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    color: Color(0xFF8F8F94),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (planTags.isNotEmpty)
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 3,
                              runSpacing: 3,
                              children: [
                                for (final tag in planTags)
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 78,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFB6812D),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tag,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFFF1D084),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _ShopSetPlanDetailPage(
                                  plan: plan,
                                  shopName: shopName,
                                  shopImage: shopImage,
                                  castNames: castNames,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 58,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE4BB69),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '予約',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF21170B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          /*
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF11100F),
              border: Border.all(color: const Color(0xFF6B4D20)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2115),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_bar_outlined,
                    size: 28,
                    color: Color(0xFFF1D084),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${plan['name'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${plan['description'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFBDBDC2),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '¥${plan['price'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFF1D084),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 58,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4BB69),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '予約',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF21170B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          */
        ],
      ],
    );
  }
}

class _ShopSetPlanDetailPage extends StatelessWidget {
  const _ShopSetPlanDetailPage({
    required this.plan,
    required this.shopName,
    required this.shopImage,
    this.castNames = const [],
  });

  final Map<String, dynamic> plan;
  final String shopName;
  final String shopImage;
  final List<String> castNames;

  String _value(String key, [String fallback = '']) {
    final value = plan[key];
    return value == null || value.toString().trim().isEmpty
        ? fallback
        : value.toString().trim();
  }

  List<String> get _tags => plan['tags'] is List
      ? (plan['tags'] as List)
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty)
            .toList()
      : const [];

  int _amount(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formattedAmount(int value) => value <= 0
      ? ''
      : value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

  String _purchasePrice(String originalPrice) {
    final salePrice = _value('sale_price');
    if (salePrice.isNotEmpty && _amount(salePrice) > 0) {
      return _formattedAmount(_amount(salePrice));
    }
    final original = _amount(originalPrice);
    final discountValue = _amount(_value('discount_value'));
    final discountType = _value('discount_type');
    final discounted = switch (discountType) {
      'amount' => original - discountValue,
      'percent' ||
      'percentage' => original - ((original * discountValue) / 100).floor(),
      _ => original,
    };
    return _formattedAmount(discounted > 0 ? discounted : original);
  }

  @override
  Widget build(BuildContext context) {
    final originalPrice = _formattedAmount(_amount(_value('price', '6,000')));
    final price = _purchasePrice(originalPrice);
    final planName = _value('name', '初回限定プラン');
    final description = _value('description', '50分 / 飲み放題 / 税サ込');
    const duration = '60分';
    final discount = _amount(originalPrice) - _amount(price);

    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 430.0);
            return Center(
              child: SizedBox(
                width: width,
                child: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _PlanDetailTopBar(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 144),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _planHero(
                                  planName: planName,
                                  description: description,
                                  price: price,
                                  originalPrice: originalPrice,
                                ),
                                const SizedBox(height: 8),
                                _planFacts(duration),
                                const SizedBox(height: 8),
                                _planContent(duration),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _usageConditions()),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _priceBreakdown(
                                        price,
                                        originalPrice,
                                        discount,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _noticeSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _PlanDetailCta(
                        price: price,
                        planName: planName,
                        onTap: () => _openProtectedSubPage(
                          context,
                          _ShopPlanReservationPage(
                            plan: plan,
                            shopName: shopName,
                            shopImage: shopImage,
                            castNames: castNames,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _planHero({
    required String planName,
    required String description,
    required String price,
    required String originalPrice,
  }) => _PlanSummaryCard(
    shopName: shopName,
    shopImage: shopImage,
    planName: planName,
    description: description,
    price: price,
    originalPrice: originalPrice,
    tags: _tags,
  );

  Widget _planFacts(String duration) => _PlanDetailPanel(
    height: 48,
    padding: 6,
    child: Row(
      children: [
        Expanded(
          child: _PlanFact(
            icon: Icons.access_time,
            label: '滞在時間',
            value: duration,
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: _PlanFact(
            icon: Icons.people_outline,
            label: '人数目安',
            value: '1-2名',
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: _PlanFact(
            icon: Icons.event_available_outlined,
            label: '予約締切',
            value: '本日 19:00まで',
          ),
        ),
      ],
    ),
  );

  Widget _planContent(String duration) => _PlanDetailSection(
    title: 'プラン内容',
    height: 92,
    child: Row(
      children: [
        Expanded(
          child: _PlanFeature(
            icon: Icons.access_time,
            title: duration,
            subtitle: 'ゆったり滞在',
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: _PlanFeature(
            icon: Icons.local_bar_outlined,
            title: '飲み放題',
            subtitle: '追加なし',
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: _PlanFeature(
            icon: Icons.percent,
            title: '税サ込',
            subtitle: '追加なし',
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: _PlanFeature(
            icon: Icons.auto_awesome,
            title: '初回来店',
            subtitle: '限定',
          ),
        ),
      ],
    ),
  );

  Widget _usageConditions() => const _PlanDetailSection(
    title: '利用条件',
    height: 112,
    child: _PlanRows(
      rows: [('初回来店', '対象'), ('利用人数', '1-2名'), ('予約期限', '当日19時まで')],
    ),
  );

  Widget _priceBreakdown(String price, String originalPrice, int discount) =>
      _PlanDetailSection(
        title: '料金構成',
        height: 112,
        child: _PlanRows(
          rows: [
            ('セット料金', '¥$originalPrice'),
            ('初回割引', discount > 0 ? '-¥${_formattedAmount(discount)}' : '—'),
            ('お支払い金額', '¥$price'),
          ],
          emphasizeLast: true,
        ),
      );

  Widget _noticeSection() => const _PlanDetailSection(
    title: '注意事項',
    height: 76,
    child: _PlanNoticeBody(),
  );
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({
    required this.shopName,
    required this.shopImage,
    required this.planName,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.tags,
  });

  final String shopName;
  final String shopImage;
  final String planName;
  final String description;
  final String price;
  final String originalPrice;
  final List<String> tags;

  Widget _image() {
    final source = shopImage.isNotEmpty
        ? shopImage
        : 'assets/home/shop-luxe-tokyo-cover-v1.png';
    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          'assets/home/shop-luxe-tokyo-cover-v1.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(source, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFB9853E), width: 1.4),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: _image()),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withAlpha(232),
                  Colors.black.withAlpha(114),
                  Colors.black.withAlpha(240),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 12,
          child: Text(
            shopName,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 14,
          top: 38,
          child: Text(
            planName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (tags.isNotEmpty)
          Positioned(
            left: 14,
            right: 14,
            top: 68,
            child: Wrap(
              spacing: 4,
              runSpacing: 3,
              children: [
                for (final tag in tags)
                  IntrinsicWidth(
                    child: Container(
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8F2F28),
                        border: Border.all(color: const Color(0xFFB24A3D)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Positioned(
          left: 14,
          top: 90,
          right: 14,
          child: Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFFD8D8DA),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¥$price',
                style: const TextStyle(
                  fontSize: 21,
                  color: Color(0xFFF1D084),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (originalPrice.isNotEmpty && originalPrice != price)
                Text(
                  '通常 ¥$originalPrice',
                  style: const TextStyle(
                    fontSize: 7,
                    color: Color(0xFFAFAFB4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ShopPlanReservationPage extends StatefulWidget {
  const _ShopPlanReservationPage({
    required this.plan,
    required this.shopName,
    required this.shopImage,
    this.castNames = const [],
  });

  final Map<String, dynamic> plan;
  final String shopName;
  final String shopImage;
  final List<String> castNames;

  @override
  State<_ShopPlanReservationPage> createState() =>
      _ShopPlanReservationPageState();
}

class _ShopPlanReservationPageState extends State<_ShopPlanReservationPage> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  int _people = 1;
  String _cast = 'なし';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _castOptions {
    final planCasts = widget.plan['cast_names'] is List
        ? (widget.plan['cast_names'] as List)
              .map((cast) => cast.toString().trim())
              .where((cast) => cast.isNotEmpty)
              .toList()
        : const <String>[];
    return {...widget.castNames, ...planCasts}.toList();
  }

  Future<void> _pickCast() async {
    final options = ['なし', ..._castOptions.where((cast) => cast != 'なし')];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('指名キャストを選択'), enabled: false),
            for (final cast in options)
              ListTile(
                title: Text(cast),
                trailing: cast == _cast
                    ? const Icon(Icons.check, color: Color(0xFFD7B56D))
                    : null,
                onTap: () => Navigator.of(context).pop(cast),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _cast = selected);
    }
  }

  int get _maxPeople {
    final value = int.tryParse('${widget.plan['max_people'] ?? ''}') ?? 0;
    return value > 0 ? value : 2;
  }

  @override
  void initState() {
    super.initState();
    if (_people > _maxPeople) _people = _maxPeople;
  }

  String _dateLabel() {
    final today = DateTime.now();
    final date = DateTime(_date.year, _date.month, _date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (date == todayOnly) return '本日 ${_date.month}/${_date.day}';
    return '${_date.month}/${_date.day}';
  }

  String _timeLabel() {
    final hour = _time.hour.toString().padLeft(2, '0');
    final minute = _time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year, now.month + 2, 0);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate) ? firstDate : _date,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (date) {
        final day = DateTime(date.year, date.month, date.day);
        return !day.isBefore(firstDate) && !day.isAfter(lastDate);
      },
      helpText: '来店日を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickTime() async {
    var hour = _time.hour;
    var minute = (_time.minute ~/ 15) * 15;
    final selected = await showDialog<TimeOfDay>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('来店時間を選択'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<int>(
                value: hour,
                items: [
                  for (var value = 0; value < 24; value++)
                    DropdownMenuItem(
                      value: value,
                      child: Text(value.toString().padLeft(2, '0')),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => hour = value);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 18)),
              ),
              DropdownButton<int>(
                value: minute,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('00')),
                  DropdownMenuItem(value: 15, child: Text('15')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 45, child: Text('45')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => minute = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(TimeOfDay(hour: hour, minute: minute)),
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _time = selected);
    }
  }

  String _value(String key, [String fallback = '']) {
    final value = widget.plan[key];
    return value == null || value.toString().trim().isEmpty
        ? fallback
        : value.toString().trim();
  }

  int _amount(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _price() {
    final original = _amount(_value('price', '6000'));
    final sale = _amount(_value('sale_price'));
    if (sale > 0) {
      return sale.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
    }
    final discount = _amount(_value('discount_value'));
    final type = _value('discount_type');
    final result = type == 'amount'
        ? original - discount
        : type == 'percent' || type == 'percentage'
        ? original - ((original * discount) / 100).floor()
        : original;
    return (result > 0 ? result : original).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _totalPrice(String price) {
    final total = _amount(price) * _people;
    return total.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _originalPrice() {
    final amount = _amount(_value('price', '6000'));
    return amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    final planName = _value('name', '初回限定プラン');
    final description = _value('description', '50分 / 飲み放題 / 税サ込');
    final price = _price();
    final totalPrice = _totalPrice(price);
    final originalPrice = _originalPrice();
    final tags = widget.plan['tags'] is List
        ? (widget.plan['tags'] as List)
              .map((tag) => tag.toString().trim())
              .where((tag) => tag.isNotEmpty)
              .toList()
        : const <String>[];
    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 430.0);
            return Center(
              child: SizedBox(
                width: width,
                child: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ReservationTopBar(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 144),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PlanSummaryCard(
                                  shopName: widget.shopName,
                                  shopImage: widget.shopImage,
                                  planName: planName,
                                  description: description,
                                  price: price,
                                  originalPrice: originalPrice,
                                  tags: tags,
                                ),
                                const SizedBox(height: 8),
                                const _ReservationSectionTitle(title: '来店日時'),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ReservationDropdown(
                                        label: '日付',
                                        value: _dateLabel(),
                                        onTap: _pickDate,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ReservationDropdown(
                                        label: '時間',
                                        value: _timeLabel(),
                                        onTap: _pickTime,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const _ReservationSectionTitle(title: '予約内容'),
                                const SizedBox(height: 6),
                                _ReservationPanel(
                                  height: 46,
                                  child: _ReservationPeopleRow(
                                    people: _people,
                                    maxPeople: _maxPeople,
                                    onMinus: _people > 1
                                        ? () => setState(() => _people--)
                                        : null,
                                    onPlus: _people < _maxPeople
                                        ? () => setState(() => _people++)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ReservationPanel(
                                  height: 46,
                                  child: _ReservationCastRow(
                                    cast: _cast,
                                    onTap: _pickCast,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ReservationPanel(
                                  height: 64,
                                  child: TextField(
                                    controller: _noteController,
                                    maxLines: 2,
                                    textInputAction: TextInputAction.newline,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '要望・来店時の相談事項を入力',
                                      hintStyle: TextStyle(
                                        fontSize: 8,
                                        color: Color(0xFF8F8F94),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ReservationCta(
                        price: totalPrice,
                        people: _people,
                        time: _timeLabel(),
                        onTap: () => _openProtectedSubPage(
                          context,
                          _ShopPlanPaymentPage(
                            plan: widget.plan,
                            shopName: widget.shopName,
                            shopImage: widget.shopImage,
                            castNames: widget.castNames,
                            people: _people,
                            date: _dateLabel(),
                            visitDate: _date,
                            time: _timeLabel(),
                            visitTime: _time,
                            cast: _cast,
                            remark: _noteController.text.trim(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShopPlanPaymentPage extends StatefulWidget {
  const _ShopPlanPaymentPage({
    required this.plan,
    required this.shopName,
    required this.shopImage,
    required this.castNames,
    required this.people,
    required this.date,
    required this.visitDate,
    required this.time,
    required this.visitTime,
    required this.cast,
    required this.remark,
  });

  final Map<String, dynamic> plan;
  final String shopName;
  final String shopImage;
  final List<String> castNames;
  final int people;
  final String date;
  final DateTime visitDate;
  final String time;
  final TimeOfDay visitTime;
  final String cast;
  final String remark;

  @override
  State<_ShopPlanPaymentPage> createState() => _ShopPlanPaymentPageState();
}

class _ShopPlanPaymentPageState extends State<_ShopPlanPaymentPage> {
  String _method = 'card';
  CouponData? _coupon;
  late Future<List<CouponData>> _couponFuture = CouponApi().fetchCoupons(
    token: AppSession.token,
  );

  Future<void> _submitPayment() async {
    final visitDateTime = DateTime(
      widget.visitDate.year,
      widget.visitDate.month,
      widget.visitDate.day,
      widget.visitTime.hour,
      widget.visitTime.minute,
    );
    final result = await OrderApi().createReservation(
      shopName: widget.shopName,
      castName: widget.cast,
      visitTime: visitDateTime.millisecondsSinceEpoch ~/ 1000,
      peopleCount: widget.people,
      amount: _amount(_totalPrice()),
      token: AppSession.token,
      remark: widget.remark,
      couponCode: _coupon?.code ?? '',
    );
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('予約の登録に失敗しました')));
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => _ShopPlanPaymentCompletePage(
          plan: widget.plan,
          shopName: widget.shopName,
          shopImage: widget.shopImage,
          people: widget.people,
          date: widget.date,
          time: widget.time,
          cast: widget.cast,
          method: _method,
          totalPrice: _totalPrice(),
          orderNo: '${result['order_no'] ?? ''}',
        ),
      ),
    );
  }

  String _value(String key, [String fallback = '']) {
    final value = widget.plan[key];
    return value == null || value.toString().trim().isEmpty
        ? fallback
        : value.toString().trim();
  }

  int _amount(Object? value) =>
      int.tryParse('${value ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formatted(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  String _unitPrice() {
    final original = _amount(_value('price', '6000'));
    final sale = _amount(_value('sale_price'));
    if (sale > 0) return _formatted(sale);
    final discount = _amount(_value('discount_value'));
    final type = _value('discount_type');
    final result = type == 'amount'
        ? original - discount
        : type == 'percent' || type == 'percentage'
        ? original - ((original * discount) / 100).floor()
        : original;
    return _formatted(result > 0 ? result : original);
  }

  String _totalPrice() => _formatted(_amount(_unitPrice()) * widget.people);

  int _couponDiscount() {
    final base = _amount(_unitPrice()) * widget.people;
    if (_coupon == null) return 0;
    if (_coupon!.discountType == 'percent')
      return (base * _coupon!.discountValue / 100).floor();
    return _coupon!.discountValue.clamp(0, base);
  }

  String _payablePrice() => _formatted(
    (_amount(_totalPrice()) - _couponDiscount()).clamp(0, 1 << 31),
  );

  Future<void> _pickCoupon(List<CouponData> coupons) async {
    final selected = await showModalBottomSheet<CouponData?>(
      context: context,
      backgroundColor: const Color(0xFF111110),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'クーポンを選択',
              style: TextStyle(
                color: Color(0xFFF1D084),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('使用しない', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, null),
            ),
            ...coupons.map(
              (coupon) => ListTile(
                title: Text(
                  coupon.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  coupon.discountType == 'percent'
                      ? '${coupon.discountValue}%OFF'
                      : '¥${coupon.discountValue}割引',
                  style: const TextStyle(color: Color(0xFFD7B56D)),
                ),
                onTap: () => Navigator.pop(context, coupon),
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(() => _coupon = selected);
  }

  @override
  Widget build(BuildContext context) {
    final planName = _value('name', '初回限定プラン');
    final description = _value('description', '50分 / 飲み放題 / 税サ込');
    final original = _formatted(_amount(_value('price', '6000')));
    final price = _unitPrice();
    final total = _totalPrice();
    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 430.0);
            return Center(
              child: SizedBox(
                width: width,
                child: Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _PaymentTopBar(
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 96),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PlanSummaryCard(
                                  shopName: widget.shopName,
                                  shopImage: widget.shopImage,
                                  planName: planName,
                                  description: description,
                                  price: price,
                                  originalPrice: original,
                                  tags: widget.plan['tags'] is List
                                      ? (widget.plan['tags'] as List)
                                            .map((tag) => tag.toString())
                                            .toList()
                                      : const [],
                                ),
                                const SizedBox(height: 12),
                                const _PaymentSectionTitle(title: '支払い方法'),
                                const SizedBox(height: 6),
                                _PaymentMethodTile(
                                  selected: _method == 'card',
                                  icon: Icons.credit_card_outlined,
                                  title: 'クレジットカード',
                                  subtitle: '**** **** **** 1234',
                                  onTap: () => setState(() => _method = 'card'),
                                ),
                                FutureBuilder<List<CouponData>>(
                                  future: _couponFuture,
                                  builder: (context, snapshot) {
                                    final coupons =
                                        (snapshot.data ?? const <CouponData>[])
                                            .where(
                                              (coupon) =>
                                                  coupon.status == 'available',
                                            )
                                            .toList();
                                    return Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        const _PaymentSectionTitle(
                                          title: 'クーポン',
                                        ),
                                        const SizedBox(height: 6),
                                        _PaymentMethodTile(
                                          selected: _coupon != null,
                                          icon: Icons.confirmation_num_outlined,
                                          title: _coupon?.name ?? 'クーポンを選択',
                                          subtitle: _coupon == null
                                              ? (coupons.isEmpty
                                                    ? '利用可能なクーポンはありません'
                                                    : '利用可能なクーポンがあります')
                                              : (_coupon!.discountType ==
                                                        'percent'
                                                    ? '${_coupon!.discountValue}%OFF'
                                                    : '¥${_coupon!.discountValue}割引'),
                                          onTap: coupons.isEmpty
                                              ? () =>
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          '利用可能なクーポンはありません',
                                                        ),
                                                      ),
                                                    )
                                              : () => _pickCoupon(coupons),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                const _PaymentSectionTitle(title: '予約内容'),
                                const SizedBox(height: 6),
                                _PaymentInfoPanel(
                                  rows: [
                                    ('来店日', widget.date),
                                    ('来店時間', widget.time),
                                    ('人数', '${widget.people}名'),
                                    ('指名', widget.cast),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const _PaymentSectionTitle(title: '支払い金額'),
                                const SizedBox(height: 6),
                                _PaymentAmountPanel(
                                  unitPrice: price,
                                  people: widget.people,
                                  totalPrice: _payablePrice(),
                                  couponDiscount: _couponDiscount(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _PaymentCta(
                        totalPrice: _payablePrice(),
                        onTap: _submitPayment,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShopPlanPaymentCompletePage extends StatelessWidget {
  const _ShopPlanPaymentCompletePage({
    required this.plan,
    required this.shopName,
    required this.shopImage,
    required this.people,
    required this.date,
    required this.time,
    required this.cast,
    required this.method,
    required this.totalPrice,
    required this.orderNo,
  });

  final Map<String, dynamic> plan;
  final String shopName;
  final String shopImage;
  final int people;
  final String date;
  final String time;
  final String cast;
  final String method;
  final String totalPrice;
  final String orderNo;

  String _value(String key, [String fallback = '']) {
    final value = plan[key];
    return value == null || value.toString().trim().isEmpty
        ? fallback
        : value.toString().trim();
  }

  int _amount(Object? value) =>
      int.tryParse('${value ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _formatted(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  String _unitPrice() {
    final original = _amount(_value('price', '6000'));
    final sale = _amount(_value('sale_price'));
    if (sale > 0) return _formatted(sale);
    final discount = _amount(_value('discount_value'));
    final type = _value('discount_type');
    final result = type == 'amount'
        ? original - discount
        : type == 'percent' || type == 'percentage'
        ? original - ((original * discount) / 100).floor()
        : original;
    return _formatted(result > 0 ? result : original);
  }

  String get _methodLabel => method == 'cash' ? '店頭で支払う' : 'クレジットカード';

  @override
  Widget build(BuildContext context) {
    final planName = _value('name', '初回限定プラン');
    final description = _value('description', '50分 / 飲み放題 / 税サ込');
    final original = _formatted(_amount(_value('price', '6000')));
    final tags = plan['tags'] is List
        ? (plan['tags'] as List).map((tag) => tag.toString()).toList()
        : const <String>[];
    return Scaffold(
      backgroundColor: const Color(0xFF020202),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(320.0, 430.0);
            return Center(
              child: SizedBox(
                width: width,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _PaymentTopBar(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF132117),
                                border: Border.all(
                                  color: const Color(0xFF72C45A),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 34,
                                    color: Color(0xFF8BEA62),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    '支払いが完了しました',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFBFF0AD),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _PaymentSectionTitle(title: 'セットプラン'),
                            const SizedBox(height: 6),
                            _PlanSummaryCard(
                              shopName: shopName,
                              shopImage: shopImage,
                              planName: planName,
                              description: description,
                              price: _unitPrice(),
                              originalPrice: original,
                              tags: tags,
                            ),
                            const SizedBox(height: 12),
                            const _PaymentSectionTitle(title: '支払い情報'),
                            const SizedBox(height: 6),
                            _PaymentInfoPanel(
                              rows: [
                                ('注文番号', orderNo),
                                ('支払い方法', _methodLabel),
                                ('支払い金額', '¥$totalPrice'),
                                ('来店時間', '$date / $time'),
                                ('人数', '${people.toString()}名'),
                                ('指名', cast),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _CompletionActionButton(
                              label: 'ホームへ',
                              filled: true,
                              onTap: () => _openHomePage(context),
                            ),
                            const SizedBox(height: 8),
                            _CompletionActionButton(
                              label: '注文履歴を見る',
                              onTap: () => _openOrderPage(
                                context,
                                AppSession.currentArea,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompletionActionButton extends StatelessWidget {
  const _CompletionActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFE0BB69) : const Color(0xFF111110),
        border: Border.all(
          color: filled ? const Color(0xFFE0BB69) : const Color(0xFFB9853E),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: filled ? const Color(0xFF111111) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _PaymentTopBar extends StatelessWidget {
  const _PaymentTopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: Color(0xFFD7B56D)),
            tooltip: '戻る',
          ),
        ),
        const Text(
          'お支払い',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFFD7B56D),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PaymentSectionTitle extends StatelessWidget {
  const _PaymentSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 2, height: 16, color: const Color(0xFFD7B56D)),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(
          color: selected ? const Color(0xFFD7B56D) : const Color(0xFF3D3A35),
          width: selected ? 1.3 : 1,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD7B56D)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 7,
                    color: Color(0xFF9E9EA3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? const Color(0xFFD7B56D) : const Color(0xFF6D6862),
          ),
        ],
      ),
    ),
  );
}

class _PaymentInfoPanel extends StatelessWidget {
  const _PaymentInfoPanel({required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  rows[index].$1,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFFBDBDC2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  rows[index].$2,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (index < rows.length - 1)
            const Divider(height: 1, color: Color(0xFF34312D)),
        ],
      ],
    ),
  );
}

class _PaymentAmountPanel extends StatelessWidget {
  const _PaymentAmountPanel({
    required this.unitPrice,
    required this.people,
    required this.totalPrice,
    this.couponDiscount = 0,
  });

  final String unitPrice;
  final int people;
  final String totalPrice;
  final int couponDiscount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFFB9853E)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        _PaymentAmountRow(label: 'セット料金', value: '¥$unitPrice'),
        const SizedBox(height: 8),
        _PaymentAmountRow(label: '人数', value: '${people.toString()}名'),
        if (couponDiscount > 0) ...[
          const SizedBox(height: 8),
          _PaymentAmountRow(
            label: 'クーポン割引',
            value: '-¥${couponDiscount.toString()}',
          ),
        ],
        const Divider(height: 20, color: Color(0xFF3D3A35)),
        Row(
          children: [
            const Text(
              'お支払い金額',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '¥$totalPrice',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PaymentAmountRow extends StatelessWidget {
  const _PaymentAmountRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          color: Color(0xFFBDBDC2),
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _PaymentCta extends StatelessWidget {
  const _PaymentCta({required this.totalPrice, required this.onTap});
  final String totalPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: const BoxDecoration(
      color: Color(0xF5090909),
      border: Border(top: BorderSide(color: Color(0xFF3B362F))),
    ),
    child: Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '合計',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFFAFAFB4),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '¥$totalPrice',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 184,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE0BB69),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '支払いを完了する',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReservationTopBar extends StatelessWidget {
  const _ReservationTopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: Color(0xFFD7B56D)),
            tooltip: '戻る',
          ),
        ),
        const Text(
          'プラン予約',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFFD7B56D),
            fontWeight: FontWeight.w800,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border,
                  color: Color(0xFFD7B56D),
                ),
                tooltip: 'お気に入り',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.ios_share, color: Color(0xFFD7B56D)),
                tooltip: '共有',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReservationSectionTitle extends StatelessWidget {
  const _ReservationSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 2, height: 16, color: const Color(0xFFD7B56D)),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ReservationDropdown extends StatelessWidget {
  const _ReservationDropdown({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 42,
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF3D3A35)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 7,
                    color: Color(0xFF9E9EA3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Color(0xFFB9853E),
          ),
        ],
      ),
    ),
  );
}

class _ReservationPanel extends StatelessWidget {
  const _ReservationPanel({required this.child, this.height = 70});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: child,
  );
}

class _ReservationPeopleRow extends StatelessWidget {
  const _ReservationPeopleRow({
    required this.people,
    required this.maxPeople,
    required this.onMinus,
    required this.onPlus,
  });
  final int people;
  final int maxPeople;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: Row(
      children: [
        const Icon(Icons.people_outline, size: 16, color: Color(0xFFD7B56D)),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '人数',
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              maxPeople == 1 ? '1名まで利用可能' : '1-$maxPeople名まで利用可能',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFFAFAFB4),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        _ReservationCircleButton(label: '-', onTap: onMinus),
        const SizedBox(width: 8),
        Text(
          '$people',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        _ReservationCircleButton(label: '+', onTap: onPlus),
      ],
    ),
  );
}

class _ReservationCircleButton extends StatelessWidget {
  const _ReservationCircleButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF24211D),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: onTap == null
              ? const Color(0xFF6D6862)
              : const Color(0xFFD7B56D),
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _ReservationCastRow extends StatelessWidget {
  const _ReservationCastRow({required this.cast, required this.onTap});
  final String cast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      height: 34,
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 16, color: Color(0xFFD7B56D)),
          const SizedBox(width: 10),
          const Text(
            '指名',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            cast,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFFD8D8DA),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (cast != 'なし') ...[
            const SizedBox(width: 6),
            Container(
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF172819),
                border: Border.all(color: const Color(0xFF7ACD54)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '出勤中',
                style: TextStyle(
                  fontSize: 7,
                  color: Color(0xFF8BEA62),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: Color(0xFFB9853E)),
        ],
      ),
    ),
  );
}

class _ReservationCta extends StatelessWidget {
  const _ReservationCta({
    required this.price,
    required this.people,
    required this.time,
    required this.onTap,
  });
  final String price;
  final int people;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xEE090909),
      border: Border(top: BorderSide(color: Color(0xFF3B362F))),
    ),
    child: Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '合計',
              style: TextStyle(
                fontSize: 7.5,
                color: Color(0xFFAFAFB4),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '¥$price',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          '$people名 / $time',
          style: const TextStyle(
            fontSize: 7.5,
            color: Color(0xFFAFAFB4),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 168,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE0BB69),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '支払いへ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlanDetailTopBar extends StatelessWidget {
  const _PlanDetailTopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: Color(0xFFD7B56D)),
            tooltip: '戻る',
          ),
        ),
        const Text(
          'プラン詳細',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFFD7B56D),
            fontWeight: FontWeight.w800,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.ios_share, color: Color(0xFFD7B56D)),
            tooltip: '共有',
          ),
        ),
      ],
    ),
  );
}

class _PlanDetailPanel extends StatelessWidget {
  const _PlanDetailPanel({
    required this.child,
    required this.height,
    this.padding = 0,
  });
  final Widget child;
  final double height;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: child,
  );
}

class _PlanDetailSection extends StatelessWidget {
  const _PlanDetailSection({
    required this.title,
    required this.height,
    required this.child,
  });
  final String title;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 2, height: 16, color: const Color(0xFFD7B56D)),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    ),
  );
}

class _PlanFact extends StatelessWidget {
  const _PlanFact({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF17130E),
      border: Border.all(color: const Color(0xFF4A4035)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD7B56D)),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 7,
                  color: Color(0xFF9E9EA3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD7B56D)),
        const SizedBox(height: 4),
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 7.6,
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 6.2,
            color: Color(0xFFAFAFB4),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PlanRows extends StatelessWidget {
  const _PlanRows({required this.rows, this.emphasizeLast = false});
  final List<(String, String)> rows;
  final bool emphasizeLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Expanded(
            child: Row(
              children: [
                Text(
                  rows[index].$1,
                  style: const TextStyle(
                    fontSize: 7.5,
                    color: Color(0xFFD8D8DA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  rows[index].$2,
                  style: TextStyle(
                    fontSize: index == rows.length - 1 && emphasizeLast
                        ? 12
                        : 8.5,
                    color: index == rows.length - 1 && emphasizeLast
                        ? const Color(0xFFF1D084)
                        : const Color(0xFFAFAFB4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (index < rows.length - 1)
            const Divider(height: 1, color: Color(0xFF2E2C29)),
        ],
      ],
    ),
  );
}

class _PlanNoticeBody extends StatelessWidget {
  const _PlanNoticeBody();

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 14, color: Color(0xFFD7B56D)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '延長・追加ドリンクは店舗にて別途お支払いください。混雑状況により案内時間が前後する場合があります。',
            style: TextStyle(
              fontSize: 8,
              height: 1.45,
              color: Color(0xFFBDBDC2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlanDetailCta extends StatelessWidget {
  const _PlanDetailCta({
    required this.price,
    required this.planName,
    required this.onTap,
  });
  final String price;
  final String planName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xEE090909),
      border: Border(top: BorderSide(color: Color(0xFF3B362F))),
    ),
    child: Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '税込',
              style: TextStyle(
                fontSize: 7.5,
                color: Color(0xFFAFAFB4),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '¥$price',
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFFF1D084),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            planName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 7.5,
              color: Color(0xFFAFAFB4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 168,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE0BB69),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'このプランで予約',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 14, color: Color(0xFF111111)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShopDetailPopularCasts extends StatelessWidget {
  const _ShopDetailPopularCasts({required this.casts});

  final List<CastData> casts;

  @override
  Widget build(BuildContext context) {
    if (casts.isEmpty) return const SizedBox.shrink();
    final visibleCasts = casts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '人気キャスト',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 136,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var index = 0; index < visibleCasts.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                CastCard(
                  cast: visibleCasts[index],
                  onTap: () => _openCastDetail(context, visibleCasts[index]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceInfoRow extends StatelessWidget {
  const _PriceInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFF1D084),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFD0D0D2),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _PriceInfoDivider extends StatelessWidget {
  const _PriceInfoDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFF625D56));
}

class DesktopRow extends StatelessWidget {
  const DesktopRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x99100F0E),
        border: Border.all(color: const Color(0xFF2A261F)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class DesktopHeader extends StatelessWidget {
  const DesktopHeader({
    super.key,
    required this.area,
    required this.areaOptions,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
  });

  final String area;
  final List<AreaData> areaOptions;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xCC0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A261F))),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: CabaNightLogo(fontSize: 32),
            ),
          ),
          const SizedBox(width: 28),
          LocationChip(
            area: area,
            areaOptions: areaOptions,
            onAreaSelected: onAreaSelected,
          ),
          const Spacer(),
          SizedBox(
            width: 360,
            child: AiSearchBar(
              controller: searchController,
              onSearch: onSearch,
            ),
          ),
          const SizedBox(width: 24),
          const NoticeBellButton(iconSize: 26),
        ],
      ),
    );
  }
}

class HomeGlow extends StatelessWidget {
  const HomeGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 0.88,
          colors: [Color(0xAA2C2312), Color(0x00020202)],
        ),
      ),
    );
  }
}

class TopHeader extends StatelessWidget {
  const TopHeader({
    super.key,
    required this.area,
    required this.areaOptions,
    required this.onAreaSelected,
    required this.searchController,
    required this.onSearch,
    this.showSearch = true,
  });

  final String area;
  final List<AreaData> areaOptions;
  final ValueChanged<String> onAreaSelected;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: showSearch ? 116 : 76,
      child: Column(
        children: [
          const SizedBox(height: 18),
          HeaderRow(
            area: area,
            areaOptions: areaOptions,
            onAreaSelected: onAreaSelected,
          ),
          if (showSearch) ...[
            const SizedBox(height: 8),
            AiSearchBar(controller: searchController, onSearch: onSearch),
          ],
        ],
      ),
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({
    super.key,
    required this.area,
    required this.areaOptions,
    required this.onAreaSelected,
  });

  final String area;
  final List<AreaData> areaOptions;
  final ValueChanged<String> onAreaSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 116),
                child: LocationChip(
                  area: area,
                  areaOptions: areaOptions,
                  onAreaSelected: onAreaSelected,
                ),
              ),
            ),
            const CabaNightLogo(fontSize: 30),
            Align(
              alignment: Alignment.centerRight,
              child: const NoticeBellButton(iconSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class CabaNightLogo extends StatelessWidget {
  const CabaNightLogo({super.key, required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          'Caba Night',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFD7B56D),
            height: 1,
          ),
        ),
        Positioned(
          right: -9,
          top: -4,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: fontSize * 0.36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF1D084),
              height: 1,
            ),
          ),
        ),
        Positioned(
          right: -17,
          top: -2,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: fontSize * 0.18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF1D084),
              height: 1,
            ),
          ),
        ),
        Positioned(
          left: -10,
          bottom: 1,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: fontSize * 0.16,
              fontWeight: FontWeight.w800,
              color: const Color(0x99F1D084),
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class LocationChip extends StatelessWidget {
  const LocationChip({
    super.key,
    required this.area,
    required this.areaOptions,
    required this.onAreaSelected,
  });

  final String area;
  final List<AreaData> areaOptions;
  final ValueChanged<String> onAreaSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAreaPicker(context),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xDD141312),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 15, color: Color(0xFFD7B56D)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAreaPicker(BuildContext context) {
    final options = areaOptions.isEmpty
        ? [AreaData(id: 0, name: area)]
        : areaOptions;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11100F),
      barrierColor: Colors.black.withAlpha(150),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'エリアを選択',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFF2A261F)),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option.name == area;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected
                                ? const Color(0xFFF1D084)
                                : Colors.white,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFF1D084),
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          onAreaSelected(option.name);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AiSearchBar extends StatelessWidget {
  const AiSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(280.0, 360.0)
            : 332.0;

        return Center(
          child: Container(
            width: width,
            height: 46,
            padding: const EdgeInsets.only(left: 20, right: 7),
            decoration: BoxDecoration(
              color: const Color(0xEE171716),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              children: [
                const Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF1D084),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    cursorColor: Color(0xFFD7B56D),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearch,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '店舗名・キャスト・エリアで検索',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA9A9AD),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onSearch(controller.text),
                    child: Ink(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFEED188), Color(0xFFB9883F)],
                        ),
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 14,
                            color: Color(0xFF070707),
                          ),
                          Positioned(
                            left: 6,
                            top: 2,
                            child: Text(
                              '✦',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF070707),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 4,
                            child: Text(
                              '✦',
                              style: TextStyle(
                                fontSize: 5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF070707),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.showSeeAll = true,
    this.onSeeAll,
  });

  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 19,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1D084), Color(0xFFA8762D)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (showSeeAll) ...[
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onSeeAll,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                child: Text(
                  'すべて見る',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9C9CC),
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFFB9924D),
            ),
          ],
        ],
      ),
    );
  }
}

class PopularShopsSection extends StatelessWidget {
  const PopularShopsSection({
    super.key,
    required this.shops,
    this.onSeeAll,
    this.onShopTap,
    this.onBook,
  });

  final List<ShopData> shops;
  final VoidCallback? onSeeAll;
  final ValueChanged<ShopData>? onShopTap;
  final ValueChanged<ShopData>? onBook;

  @override
  Widget build(BuildContext context) {
    final visibleShops = shops
        .where((shop) => shop.isRecommended)
        .take(10)
        .toList();

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Column(
        children: [
          SectionHeader(title: '人気店舗', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (final shop in visibleShops) ...[
                  ShopCard(
                    shop: shop,
                    onTap: () => onShopTap?.call(shop),
                    onBook: () => onBook?.call(shop),
                  ),
                  if (shop != visibleShops.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, this.onTap, this.onBook});

  final ShopData shop;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${shop.name} 店舗詳細',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 106,
          height: 174,
          decoration: BoxDecoration(
            color: const Color(0xFF151514),
            borderRadius: BorderRadius.circular(7),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              ShopCoverImage(shop: shop),
              Positioned(
                left: 0,
                right: 0,
                top: 60,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(0),
                        const Color(0xFF151514),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 0,
                child: Container(
                  width: 22,
                  height: 36,
                  color: Color(shop.ribbonColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '♛',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF7E6B1),
                          height: 1,
                        ),
                      ),
                      Text(
                        shop.rank,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 91,
                child: Text(
                  shop.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 113,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 10,
                      color: Color(0xFFD7B56D),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      shop.area,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB7B7BA),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                top: 128,
                child: Row(
                  children: [
                    const Text(
                      '★',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF1D084),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.score,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF1D084),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      '|',
                      style: TextStyle(fontSize: 10, color: Color(0xFF7D7D80)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      shop.count,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB7B7BA),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: GoldButton(height: 18, fontSize: 9, onTap: onBook),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopCoverImage extends StatelessWidget {
  const ShopCoverImage({super.key, required this.shop});

  final ShopData shop;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        shop.asset.startsWith('http://') || shop.asset.startsWith('https://');
    final fallback = Image.asset(
      shop.fallbackAsset,
      width: 106,
      height: 84,
      fit: BoxFit.cover,
    );

    if (!isNetwork) {
      return Image.asset(shop.asset, width: 106, height: 84, fit: BoxFit.cover);
    }

    return Image.network(
      shop.asset,
      width: 106,
      height: 84,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class PopularCastSection extends StatelessWidget {
  const PopularCastSection({super.key, required this.casts, this.onSeeAll});

  final List<CastData> casts;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final visibleCasts = casts
        .where((cast) => cast.isRecommended)
        .take(10)
        .toList();

    return SizedBox(
      width: double.infinity,
      height: 180,
      child: Column(
        children: [
          SectionHeader(title: '人気キャスト', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (final cast in visibleCasts) ...[
                  CastCard(
                    cast: cast,
                    onTap: () => _openCastDetail(context, cast),
                  ),
                  if (cast != visibleCasts.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CastCard extends StatelessWidget {
  const CastCard({super.key, required this.cast, this.onTap});

  final CastData cast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 78,
        height: 136,
        decoration: BoxDecoration(
          color: const Color(0xFF171716),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 5,
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 7,
              child: ClipOval(child: CastAvatarImage(cast: cast)),
            ),
            Positioned(
              left: 6,
              top: 61,
              child: Container(
                height: 15,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Color(cast.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      cast.badge,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 82,
              child: Text(
                cast.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 9,
              top: 99,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 9,
                    color: Color(0xFFD7B56D),
                  ),
                  const SizedBox(width: 1),
                  SizedBox(
                    width: 52,
                    child: Text(
                      cast.area,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 6.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB7B7BA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF121211),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  cast.button,
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Color(cast.color),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CastAvatarImage extends StatelessWidget {
  const CastAvatarImage({
    super.key,
    required this.cast,
    this.width = 62,
    this.height = 62,
  });

  final CastData cast;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        cast.asset.startsWith('http://') || cast.asset.startsWith('https://');
    final fallback = Image.asset(
      cast.fallbackAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );

    if (!isNetwork) {
      return Image.asset(
        cast.asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      cast.asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class CampaignSection extends StatelessWidget {
  const CampaignSection({super.key, required this.campaigns});

  final List<CampaignData> campaigns;

  @override
  Widget build(BuildContext context) {
    final visibleCampaigns = campaigns.take(10).toList();

    return SizedBox(
      width: double.infinity,
      height: 166,
      child: Column(
        children: [
          const SectionHeader(title: 'おすすめキャンペーン'),
          const SizedBox(height: 13),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: visibleCampaigns.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  CampaignCard(campaign: visibleCampaigns[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key, required this.campaign});

  final CampaignData campaign;

  @override
  Widget build(BuildContext context) {
    final multiLine = campaign.offer.contains('\n');
    void openPlanDetail() => Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => _ShopSetPlanDetailPage(
          plan: campaign.plan,
          shopName: campaign.shopName,
          shopImage: campaign.asset,
        ),
      ),
    );

    return GestureDetector(
      onTap: openPlanDetail,
      child: Container(
        width: 106,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF151514),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            CampaignCoverImage(campaign: campaign),
            Positioned.fill(
              bottom: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(187),
                      Colors.black.withAlpha(34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 5,
              child: Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFA7423C),
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
                child: Text(
                  campaign.tag,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFE7B9),
                  ),
                ),
              ),
            ),
            if (campaign.lead.isNotEmpty)
              Positioned(
                left: 8,
                top: 42,
                child: Text(
                  campaign.lead,
                  style: TextStyle(
                    fontSize: campaign.lead == '延長' ? 11 : 9,
                    fontWeight: FontWeight.w800,
                    color: campaign.lead == '延長'
                        ? const Color(0xFFF3D486)
                        : Colors.white,
                  ),
                ),
              ),
            Positioned(
              left: campaign.offer.startsWith('指名') ? 10 : 8,
              top: campaign.offer.startsWith('指名') ? 39 : 55,
              child: Text(
                campaign.offer,
                style: TextStyle(
                  fontSize: multiLine
                      ? 10
                      : (campaign.offer == '20%OFF' ? 20 : 16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF3D486),
                  height: multiLine ? 1.05 : 1,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 80,
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 9,
                    color: Color(0xFFAFAFAF),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    campaign.time,
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBDBDBF),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 7,
              child: GoldButton(height: 18, fontSize: 9, onTap: openPlanDetail),
            ),
          ],
        ),
      ),
    );
  }
}

class CampaignCoverImage extends StatelessWidget {
  const CampaignCoverImage({super.key, required this.campaign});

  final CampaignData campaign;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        campaign.asset.startsWith('http://') ||
        campaign.asset.startsWith('https://');
    final fallback = Image.asset(
      'assets/home/campaign-first-visit-v1.png',
      width: 106,
      height: 76,
      fit: BoxFit.cover,
    );

    if (!isNetwork) {
      return Image.asset(
        campaign.asset,
        width: 106,
        height: 76,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      campaign.asset,
      width: 106,
      height: 76,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class NewsSection extends StatelessWidget {
  const NewsSection({
    super.key,
    required this.news,
    this.onSeeAll,
    this.onNewsTap,
  });

  final List<NewsData> news;
  final VoidCallback? onSeeAll;
  final ValueChanged<NewsData>? onNewsTap;

  @override
  Widget build(BuildContext context) {
    final visibleNews = news.take(4).toList();

    return SizedBox(
      width: double.infinity,
      height: visibleNews.isEmpty ? 58 : 82 + visibleNews.length * 88,
      child: Column(
        children: [
          SectionHeader(title: 'NEWS', onSeeAll: onSeeAll),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                for (final item in visibleNews) ...[
                  NewsCard(news: item, onTap: () => onNewsTap?.call(item)),
                  if (item != visibleNews.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.onTap});

  final NewsData news;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: double.infinity,
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF151514),
            border: Border.all(color: const Color(0xFF2A261F)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: NewsLogoImage(news: news),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF241F17),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            news.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFF1D084),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          news.date,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8F8F94),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsLogoImage extends StatelessWidget {
  const NewsLogoImage({super.key, required this.news});

  final NewsData news;

  @override
  Widget build(BuildContext context) {
    final isNetwork =
        news.logo.startsWith('http://') || news.logo.startsWith('https://');
    final fallback = Container(
      width: 62,
      height: 62,
      color: const Color(0xFF241F17),
      alignment: Alignment.center,
      child: const Icon(
        Icons.article_rounded,
        size: 24,
        color: Color(0xFFF1D084),
      ),
    );

    if (news.logo.isEmpty) {
      return fallback;
    }

    if (!isNetwork) {
      return Image.asset(news.logo, width: 62, height: 62, fit: BoxFit.cover);
    }

    return Image.network(
      news.logo,
      width: 62,
      height: 62,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return fallback;
      },
    );
  }
}

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.height,
    required this.fontSize,
    this.onTap,
    this.label,
  });

  final double height;
  final double fontSize;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ThreeDButton(
      height: height,
      fontSize: fontSize,
      label: label ?? '今すぐ予約',
      onTap: onTap,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0D184), Color(0xFFB9853E)],
      ),
      textColor: const Color(0xFF0C0904),
      shadowColor: const Color(0xFF765027),
    );
  }
}

class GoldOutlineButton extends StatelessWidget {
  const GoldOutlineButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ThreeDButton(
      height: 14,
      fontSize: 8,
      textColor: Color(0xFFF3D486),
      backgroundColor: Color(0xFF171716),
      shadowColor: Color(0xFF080807),
      onTap: onTap,
    );
  }
}

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _searchController = TextEditingController();
  String _keyword = '';
  final _categories = const [
    ('予約について', Icons.calendar_month_outlined),
    ('支払い・請求', Icons.credit_card_outlined),
    ('本人確認', Icons.verified_user_outlined),
    ('店舗・キャスト', Icons.storefront_outlined),
  ];
  final _questions = const [
    '予約はどのように変更できますか？',
    '支払い方法を登録・変更したい',
    '本人確認書類の提出について',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions
        .where((item) => item.contains(_keyword))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'ヘルプ・サポート',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.search_rounded,
                        color: Color(0xFFF1D084),
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                children: [
                  _supportCard(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _keyword = value),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'キーワードで検索',
                      hintStyle: const TextStyle(
                        color: Color(0xFF85817B),
                        fontSize: 9,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFD7B56D),
                        size: 17,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111110),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4B3D2A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4B3D2A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _helpTitle('カテゴリー'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 7,
                    crossAxisSpacing: 7,
                    childAspectRatio: 2.8,
                    children: [
                      for (final category in _categories)
                        _categoryCard(category.$1, category.$2),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _helpTitle('よくある質問'),
                  _questionList(questions),
                  const SizedBox(height: 12),
                  _helpTitle('お問い合わせ'),
                  _contactCard(),
                ],
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 5),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF1D084),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _supportCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF9A7134)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'お困りですか？',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'よくある質問やお問い合わせをご案内します',
          style: TextStyle(color: Color(0xFFA9A39A), fontSize: 8),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _supportButton(
                Icons.chat_bubble_outline,
                'チャット相談',
                () => _openProtectedSubPage(context, const ChatSupportPage()),
                true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _supportButton(
                Icons.mail_outline,
                'メールで問い合わせ',
                () => _showMessage('メールで問い合わせ'),
                false,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _questionList(List<String> questions) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      children: [
        for (var i = 0; i < questions.length; i++) ...[
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -3),
            leading: const Icon(
              Icons.question_mark_rounded,
              color: Color(0xFFD7B56D),
              size: 16,
            ),
            title: Text(
              questions[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8F8069),
              size: 17,
            ),
            onTap: () => _showMessage(questions[i]),
          ),
          if (i < questions.length - 1)
            const Divider(height: 1, color: Color(0xFF302C27)),
        ],
      ],
    ),
  );
  Widget _contactCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF3D3A35)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.support_agent_outlined,
          color: Color(0xFFD7B56D),
          size: 22,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '解決しない場合はサポートへお問い合わせください',
            style: TextStyle(color: Color(0xFFDDD9D2), fontSize: 9),
          ),
        ),
        IconButton(
          onPressed: () => _showMessage('お問い合わせ'),
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFD7B56D),
          ),
        ),
      ],
    ),
  );
  Widget _supportButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool filled,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 34,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFE0BB69) : const Color(0xFF171513),
        border: Border.all(color: const Color(0xFFD0A653)),
        borderRadius: BorderRadius.circular(5),
        boxShadow: filled
            ? const [BoxShadow(color: Color(0xFF795A2B), offset: Offset(0, 2))]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 14,
            color: filled ? const Color(0xFF171513) : const Color(0xFFF1D084),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: filled ? const Color(0xFF171513) : const Color(0xFFF1D084),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _categoryCard(String label, IconData icon) => InkWell(
    onTap: () =>
        _openProtectedSubPage(context, HelpSupportCasePage(title: label)),
    borderRadius: BorderRadius.circular(5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF4A3E30)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD7B56D), size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8F8069),
            size: 15,
          ),
        ],
      ),
    ),
  );
  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$message を開きます')));
}

class ChatSupportPage extends StatefulWidget {
  const ChatSupportPage({super.key});

  @override
  State<ChatSupportPage> createState() => _ChatSupportPageState();
}

class _ChatSupportPageState extends State<ChatSupportPage> {
  final _messageController = TextEditingController();
  String _category = '予約について';
  SupportConversation _conversation = const SupportConversation.empty();
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    SupportApi().fetchLatest(token: AppSession.token).then((conversation) {
      if (mounted)
        setState(() {
          _conversation = conversation;
          _loading = false;
        });
      SupportApi().markRead(token: AppSession.token);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'お問い合わせ',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.headset_mic_outlined,
                      color: Color(0xFFF1D084),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
              children: [
                _supportIntro(),
                const SizedBox(height: 8),
                if (_loading)
                  const LinearProgressIndicator(
                    color: Color(0xFFF1D084),
                    minHeight: 2,
                  ),
                if (!_loading && _conversation.messages.isNotEmpty) ...[
                  _conversationCard(),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111110),
                    border: Border.all(color: const Color(0xFF3D3A35)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'お問い合わせ内容を確認のうえ、担当者よりご連絡いたします。',
                    style: TextStyle(
                      color: Color(0xFFCBC7C0),
                      fontSize: 9,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'お問い合わせ内容',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: const Color(0xFF191816),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF111110),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: const BorderSide(color: Color(0xFF4A3E30)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: '予約について', child: Text('予約について')),
                    DropdownMenuItem(value: '支払いについて', child: Text('支払いについて')),
                    DropdownMenuItem(
                      value: '本人確認について',
                      child: Text('本人確認について'),
                    ),
                    DropdownMenuItem(value: 'その他', child: Text('その他')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 116,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111110),
                    border: Border.all(color: const Color(0xFF4A3E30)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'お問い合わせ内容を入力してください',
                      hintStyle: TextStyle(
                        color: Color(0xFF85817B),
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _sending
                      ? null
                      : () async {
                          if (_messageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('お問い合わせ内容を入力してください'),
                              ),
                            );
                            return;
                          }
                          setState(() => _sending = true);
                          final conversation = await SupportApi().send(
                            token: AppSession.token,
                            category: _category,
                            content: _messageController.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _sending = false);
                          if (conversation == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('送信に失敗しました')),
                            );
                            return;
                          }
                          setState(() {
                            _conversation = conversation;
                            _messageController.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('お問い合わせを送信しました')),
                          );
                        },
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0BB69),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF795A2B),
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _sending ? '送信中...' : '送信する',
                      style: TextStyle(
                        color: Color(0xFF171513),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '営業時間外のお問い合わせは翌営業日に対応します',
                    style: TextStyle(color: Color(0xFF817D76), fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) => _handleDetailFooterNavigation(
              context,
              index,
              AppSession.currentArea,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _conversationCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF4A3E30)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFFF1D084),
              size: 15,
            ),
            const SizedBox(width: 6),
            const Text(
              'チャット履歴',
              style: TextStyle(
                color: Color(0xFFF1D084),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (_conversation.ticketNo.isNotEmpty)
              Text(
                _conversation.ticketNo,
                style: const TextStyle(color: Color(0xFF8E8B84), fontSize: 8),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final message in _conversation.messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: message.senderType == 'member'
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 270),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: message.senderType == 'member'
                      ? const Color(0xFF5C4826)
                      : const Color(0xFF24211D),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Color(0xFFE5E2DA),
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _supportIntro() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF9A7134)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF2A2115),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.support_agent_outlined,
            color: Color(0xFFF1D084),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'カスタマーサポート',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '通常24時間以内に返信します',
                style: TextStyle(color: Color(0xFFA9A39A), fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HelpSupportCasePage extends StatefulWidget {
  const HelpSupportCasePage({super.key, required this.title});
  final String title;

  @override
  State<HelpSupportCasePage> createState() => _HelpSupportCasePageState();
}

class _HelpSupportCasePageState extends State<HelpSupportCasePage> {
  final _searchController = TextEditingController();
  String _keyword = '';
  final _popular = const [
    '予約のキャンセル方法を教えてください',
    '予約内容を確認したい',
    '来店日時を変更できますか？',
    '予約に関する注意事項について',
  ];
  final _all = const [
    '予約するにはどうすればよいですか？',
    '人数を変更できますか？',
    '店舗やキャストを変更できますか？',
    '予約が見つからない場合について',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popular = _popular.where((item) => item.contains(_keyword)).toList();
    final all = _all.where((item) => item.contains(_keyword)).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(
                        Icons.search_rounded,
                        color: Color(0xFFF1D084),
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                children: [
                  _caseHeader(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _keyword = value),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'キーワードで検索',
                      hintStyle: const TextStyle(
                        color: Color(0xFF85817B),
                        fontSize: 9,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFD7B56D),
                        size: 17,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF111110),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4B3D2A)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF4B3D2A)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _filterChips(),
                  const SizedBox(height: 12),
                  _questionSection('よくあるご質問', popular),
                  const SizedBox(height: 12),
                  _questionSection('すべての質問', all),
                ],
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _caseHeader() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFF9A7134)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2A2115),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFFF1D084),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '予約に関するよくある質問をご案内します',
                style: TextStyle(color: Color(0xFFA9A39A), fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _filterChips() => Row(
    children: [
      _filterChip('すべて', true),
      const SizedBox(width: 6),
      _filterChip('予約前', false),
      const SizedBox(width: 6),
      _filterChip('キャンセル', false),
      const SizedBox(width: 6),
      _filterChip('来店後', false),
    ],
  );
  Widget _filterChip(String label, bool active) => Expanded(
    child: Container(
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE0BB69) : const Color(0xFF111110),
        border: Border.all(color: const Color(0xFF8F6830)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF171513) : const Color(0xFFC5C1BA),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
  Widget _questionSection(String title, List<String> questions) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _helpTitle(title),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111110),
          border: Border.all(color: const Color(0xFF3D3A35)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            for (var i = 0; i < questions.length; i++) ...[
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFFD7B56D),
                  size: 16,
                ),
                title: Text(
                  questions[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8F8069),
                  size: 17,
                ),
                onTap: () => _showMessage(questions[i]),
              ),
              if (i < questions.length - 1)
                const Divider(height: 1, color: Color(0xFF302C27)),
            ],
          ],
        ),
      ),
    ],
  );
  Widget _helpTitle(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 5),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF1D084),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$message を開きます')));
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _language = '日本語';
  String _fontSize = '標準';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '設定',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'アプリ設定',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'アプリの表示とアカウントを管理します',
                  style: TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
                ),
                const SizedBox(height: 14),
                _settingsGroup([
                  _settingsRow(
                    icon: Icons.language,
                    title: '言語',
                    value: _language,
                    onTap: _selectLanguage,
                  ),
                  _settingsRow(
                    icon: Icons.format_size,
                    title: 'フォントサイズ',
                    value: _fontSize,
                    onTap: _selectFontSize,
                  ),
                ]),
                const SizedBox(height: 12),
                _settingsRow(
                  icon: Icons.shield_outlined,
                  title: 'セキュリティ設定',
                  subtitle: 'ログインと認証に関する設定',
                  onTap: _showSecurityInfo,
                ),
                const SizedBox(height: 12),
                _settingsRow(
                  icon: Icons.delete_outline,
                  title: 'アカウント削除',
                  subtitle: 'アカウントとすべてのデータを削除',
                  danger: true,
                  onTap: _confirmDelete,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171513),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFF1D084),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '設定内容はこの端末に保存されます。アカウント削除は取り消せません。',
                          style: TextStyle(
                            color: Color(0xFFAAA39A),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) {
              if (index != 4)
                _handleDetailFooterNavigation(
                  context,
                  index,
                  AppSession.currentArea,
                );
            },
          ),
        ],
      ),
    ),
  );

  Widget _settingsGroup(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF5D4828)),
    ),
    child: Column(children: rows),
  );

  Widget _settingsRow({
    required IconData icon,
    required String title,
    String? value,
    String? subtitle,
    bool danger = false,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: danger ? const Color(0xFFE06A6A) : const Color(0xFFF1D084),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: danger ? const Color(0xFFE06A6A) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFAAA39A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Text(
              value,
              style: const TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
            ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: danger ? const Color(0xFFE06A6A) : const Color(0xFF8E8068),
          ),
        ],
      ),
    ),
  );

  Future<void> _selectLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171513),
        title: const Text('言語', style: TextStyle(color: Color(0xFFF1D084))),
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('日本語'),
            const SizedBox(height: 14),
            _languageOption('English'),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _language = selected);
  }

  Widget _languageOption(String label) => InkWell(
    onTap: () => Navigator.of(context).pop(label),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: _language == label
            ? const Color(0xFF2A241A)
            : const Color(0xFF111110),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _language == label
              ? const Color(0xFFF1D084)
              : const Color(0xFF4A3E30),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _language == label ? const Color(0xFFF1D084) : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Future<void> _selectFontSize() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171513),
        title: const Text(
          'フォントサイズ',
          style: TextStyle(color: Color(0xFFF1D084)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fontSizeOption('小', 13),
            const SizedBox(height: 14),
            _fontSizeOption('標準', 16),
            const SizedBox(height: 14),
            _fontSizeOption('大', 20),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _fontSize = selected);
  }

  Widget _fontSizeOption(String label, double size) => InkWell(
    onTap: () => Navigator.of(context).pop(label),
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _fontSize == label
            ? const Color(0xFF2A241A)
            : const Color(0xFF111110),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _fontSize == label
              ? const Color(0xFFF1D084)
              : const Color(0xFF4A3E30),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _fontSize == label ? const Color(0xFFF1D084) : Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Future<String?> _choose(String title, List<String> options) =>
      showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          backgroundColor: const Color(0xFF171513),
          title: Text(title, style: const TextStyle(color: Color(0xFFF1D084))),
          children: [
            for (final option in options)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, option),
                child: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      );

  void _showSecurityInfo() =>
      _openProtectedSubPage(context, const SecuritySettingsPage());

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171513),
        title: const Text(
          'アカウント削除',
          style: TextStyle(color: Color(0xFFE06A6A)),
        ),
        content: const Text(
          'アカウントとすべてのデータを削除します。削除後は復元できません。\n\n続行する場合は、次のアンケートに回答してください。',
          style: TextStyle(color: Colors.white, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: Color(0xFFAAA39A)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'アンケートへ',
              style: TextStyle(color: Color(0xFFE06A6A)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _openProtectedSubPage(context, const AccountDeletionPage());
    }
  }
}

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  final _feedback = TextEditingController();
  String? _reason;
  String? _reuseApp;
  bool _deleting = false;

  static const _reasons = [
    '利用する機会が少ない',
    '使い方が分かりにくい',
    'サービスに満足できない',
    '他のサービスを利用する',
    'その他',
  ];

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'アカウント削除',
                  style: TextStyle(
                    color: Color(0xFFE06A6A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _warningBox(),
                const SizedBox(height: 18),
                const Text(
                  '退会アンケート',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '今後のサービス改善のため、ご協力ください。',
                  style: TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
                ),
                const SizedBox(height: 18),
                _dropdown(
                  '退会理由',
                  _reason,
                  _reasons,
                  (value) => setState(() => _reason = value),
                ),
                const SizedBox(height: 14),
                _dropdown(
                  '今後も似たアプリを利用しますか？',
                  _reuseApp,
                  const ['はい', 'いいえ'],
                  (value) => setState(() => _reuseApp = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _feedback,
                  minLines: 4,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '本アプリへのご意見（任意）',
                    labelStyle: const TextStyle(
                      color: Color(0xFFBDBDC2),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF111110),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4A3E30)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF4A3E30)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _button(
                        'キャンセル',
                        false,
                        _deleting ? null : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _button(
                        'アカウントを削除',
                        true,
                        _deleting ? null : _confirmFinalDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _warningBox() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF241616),
      border: Border.all(color: const Color(0xFF9A4848)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFE06A6A), size: 21),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'アカウントを削除すると、予約履歴・お気に入り・保有クーポンなどのデータはすべて削除されます。削除後は復元できません。',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    value: value,
    dropdownColor: const Color(0xFF171513),
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF111110),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF4A3E30)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF4A3E30)),
      ),
    ),
    items: items
        .map((item) => DropdownMenuItem(value: item, child: Text(item)))
        .toList(),
    onChanged: onChanged,
  );

  Widget _button(String label, bool primary, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? const Color(0xFFE06A6A) : const Color(0xFF171513),
            border: primary ? null : Border.all(color: const Color(0xFF6A5634)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary ? Colors.white : const Color(0xFFF1D084),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  Future<void> _confirmFinalDelete() async {
    if (_reason == null || _reuseApp == null) {
      _showMessage('退会理由と利用予定を選択してください');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171513),
        title: const Text('最終確認', style: TextStyle(color: Color(0xFFE06A6A))),
        content: const Text(
          'アカウントを削除しますか？この操作は取り消せず、データを復元できません。',
          style: TextStyle(color: Colors.white, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('戻る', style: TextStyle(color: Color(0xFFAAA39A))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '削除を確定',
              style: TextStyle(color: Color(0xFFE06A6A)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await AuthApi().deleteAccount(
        reason: _reason!,
        reuseApp: _reuseApp!,
        feedback: _feedback.text.trim(),
        token: AppSession.token,
      );
      await AppSession.clear();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (error) {
      if (mounted)
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _faceIdEnabled = false;

  @override
  void initState() {
    super.initState();
    BiometricAuthService().isEnabled().then((enabled) {
      if (mounted) setState(() => _faceIdEnabled = enabled);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'セキュリティ設定',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'ログインと認証',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'アカウントを安全に管理します',
                  style: TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
                ),
                const SizedBox(height: 14),
                _securityAction(
                  icon: Icons.lock_outline,
                  title: 'パスワードを変更',
                  subtitle: '現在のパスワードを変更します',
                  onTap: () => _openProtectedSubPage(
                    context,
                    const ChangePasswordPage(),
                  ),
                ),
                const SizedBox(height: 12),
                _securityAction(
                  icon: Icons.help_outline,
                  title: 'パスワードを忘れた場合',
                  subtitle: 'パスワードを再設定します',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111110),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF5D4828)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.face,
                        color: Color(0xFFF1D084),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Face IDでログイン',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '次回からFace IDでログインします',
                              style: TextStyle(
                                color: Color(0xFFAAA39A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _faceIdEnabled,
                        activeColor: const Color(0xFF171513),
                        activeTrackColor: const Color(0xFFF1D084),
                        inactiveThumbColor: const Color(0xFFAAA39A),
                        inactiveTrackColor: const Color(0xFF3A342D),
                        onChanged: _toggleFaceId,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171513),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Face IDを利用するには、お使いの端末でFace IDを設定してください。',
                    style: TextStyle(color: Color(0xFFAAA39A), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) {
              if (index != 4)
                _handleDetailFooterNavigation(
                  context,
                  index,
                  AppSession.currentArea,
                );
            },
          ),
        ],
      ),
    ),
  );

  Widget _securityAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5D4828)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF1D084), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFAAA39A),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF8E8068), size: 20),
        ],
      ),
    ),
  );

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _toggleFaceId(bool value) async {
    if (!value) {
      await BiometricAuthService().disable();
      if (mounted) setState(() => _faceIdEnabled = false);
      return;
    }
    final enabled = await BiometricAuthService().enable(AppSession.token);
    if (!mounted) return;
    setState(() => _faceIdEnabled = enabled);
    if (!enabled) _showMessage('この端末ではFace IDを利用できません');
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'パスワード変更',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _saving
                        ? null
                        : () => _returnToPreviousOrLogin(context),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'パスワードを変更',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '安全のため、現在のパスワードと新しいパスワードを入力してください',
                  style: TextStyle(color: Color(0xFFAAA39A), fontSize: 12),
                ),
                const SizedBox(height: 18),
                _passwordField('現在のパスワード', _oldPassword),
                _passwordField('新しいパスワード', _password),
                _passwordField('新しいパスワード（確認）', _passwordConfirm),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'キャンセル',
                        false,
                        _saving
                            ? null
                            : () => _returnToPreviousOrLogin(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        '変更を確定',
                        true,
                        _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) {
              if (index != 4)
                _handleDetailFooterNavigation(
                  context,
                  index,
                  AppSession.currentArea,
                );
            },
          ),
        ],
      ),
    ),
  );

  Widget _passwordField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF111110),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF4A3E30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF4A3E30)),
            ),
          ),
        ),
      );

  Widget _actionButton(String label, bool primary, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? const Color(0xFFE0BB69) : const Color(0xFF171513),
            border: primary ? null : Border.all(color: const Color(0xFF6A5634)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: primary
                  ? const Color(0xFF171513)
                  : const Color(0xFFF1D084),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  Future<void> _save() async {
    if (_oldPassword.text.isEmpty ||
        _password.text.isEmpty ||
        _passwordConfirm.text.isEmpty) {
      _showMessage('すべての項目を入力してください');
      return;
    }
    if (_password.text != _passwordConfirm.text) {
      _showMessage('新しいパスワードが一致しません');
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthApi().changePassword(
        oldPassword: _oldPassword.text,
        password: _password.text,
        passwordConfirm: _passwordConfirm.text,
        token: AppSession.token,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('パスワードを変更しました')));
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted)
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    this.initialMobile,
    this.allowEmail = true,
  });

  final String? initialMobile;
  final bool allowEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _identifier = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  String _method = 'mobile';
  UserProfile? _profile;
  bool _sending = false;
  bool _saving = false;
  bool get _usesProfile =>
      AppSession.isAuthenticated && widget.initialMobile == null;
  bool get _identifierReadOnly => _usesProfile && _profile != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialMobile != null) {
      _identifier.text = widget.initialMobile!.trim();
    }
    if (_usesProfile) {
      _profile = AppSession.cachedProfile;
      _applyProfile(_profile);
      _loadProfile();
    }
  }

  void _applyProfile(UserProfile? profile) {
    if (profile == null) return;
    _identifier.text = _method == 'mobile' ? profile.mobile : profile.email;
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthApi().fetchProfile(token: AppSession.token);
      await AppSession.cacheProfile(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _applyProfile(profile);
      });
    } catch (_) {
      // Cached account data remains available when the profile request fails.
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'パスワード再設定',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _saving
                        ? null
                        : () => _returnToPreviousOrLogin(context),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  '電話番号で認証',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.allowEmail
                      ? '登録済みの携帯番号で認証してください'
                      : '登録済みの電話番号に届く認証コードでパスワードを再設定します',
                  style: const TextStyle(
                    color: Color(0xFFAAA39A),
                    fontSize: 12,
                  ),
                ),
                if (widget.allowEmail) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _methodCard(
                          'mobile',
                          Icons.phone_iphone,
                          '携帯番号',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _methodCard(
                          'email',
                          Icons.mail_outline,
                          'メールアドレス',
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _field(
                  _method == 'mobile' ? '携帯番号' : 'メールアドレス',
                  _identifier,
                  readOnly: _identifierReadOnly,
                  keyboardType: _method == 'mobile'
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                ),
                if (_method == 'email' &&
                    (_profile?.email.trim().isEmpty ?? true))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'メールアドレスが未登録です。先に登録してください。',
                            style: TextStyle(
                              color: Color(0xFFE5B7B7),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _openMemberEditPage(context, _profile);
                            _loadProfile();
                          },
                          child: const Text(
                            '登録する',
                            style: TextStyle(
                              color: Color(0xFFF1D084),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        '認証コード',
                        _code,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 132,
                      child: _actionButton(
                        '認証コードを送信',
                        false,
                        _sending ? null : _sendCode,
                      ),
                    ),
                  ],
                ),
                _passwordField('新しいパスワード', _password),
                _passwordField('新しいパスワード（確認）', _passwordConfirm),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        'キャンセル',
                        false,
                        _saving
                            ? null
                            : () => _returnToPreviousOrLogin(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionButton(
                        '再設定する',
                        true,
                        _saving ? null : _reset,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (AppSession.isAuthenticated)
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) {
                if (index != 4)
                  _handleDetailFooterNavigation(
                    context,
                    index,
                    AppSession.currentArea,
                  );
              },
            ),
        ],
      ),
    ),
  );

  Widget _methodCard(String value, IconData icon, String label) =>
      GestureDetector(
        onTap: () {
          if (value == 'email' && (_profile?.email.trim().isEmpty ?? true)) {
            _showMessage('メールアドレスを先に登録してください');
            return;
          }
          setState(() {
            _method = value;
            _code.clear();
            _applyProfile(_profile);
          });
        },
        child: Container(
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _method == value
                ? const Color(0xFFE0BB69)
                : const Color(0xFF111110),
            border: Border.all(
              color: _method == value
                  ? const Color(0xFFE0BB69)
                  : const Color(0xFF5D4828),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _method == value
                    ? const Color(0xFF171513)
                    : const Color(0xFFF1D084),
                size: 24,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: _method == value
                      ? const Color(0xFF171513)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool readOnly = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF111110),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF4A3E30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF4A3E30)),
        ),
      ),
    ),
  );

  Widget _passwordField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFFBDBDC2), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF111110),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF4A3E30)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF4A3E30)),
            ),
          ),
        ),
      );

  Widget _actionButton(String label, bool primary, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? const Color(0xFFE0BB69) : const Color(0xFF171513),
            border: primary ? null : Border.all(color: const Color(0xFF6A5634)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary
                  ? const Color(0xFF171513)
                  : const Color(0xFFF1D084),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  Future<void> _sendCode() async {
    if (_identifier.text.trim().isEmpty) {
      _showMessage('認証先を入力してください');
      return;
    }
    if (_method == 'email') {
      _showMessage('メール認証は準備中です');
      return;
    }
    setState(() => _sending = true);
    try {
      await AuthApi().sendSmsCode(
        mobile: _identifier.text.trim(),
        scene: 'ZHDLMM',
      );
      _showMessage('認証コードを送信しました');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reset() async {
    if (_method == 'email') {
      _showMessage('メール認証は準備中です');
      return;
    }
    if ([
      _identifier,
      _code,
      _password,
      _passwordConfirm,
    ].any((field) => field.text.trim().isEmpty)) {
      _showMessage('すべての項目を入力してください');
      return;
    }
    if (_password.text != _passwordConfirm.text) {
      _showMessage('新しいパスワードが一致しません');
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthApi().resetPassword(
        mobile: _identifier.text.trim(),
        code: _code.text.trim(),
        password: _password.text,
        passwordConfirm: _passwordConfirm.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('パスワードを再設定しました')));
        _returnToPreviousOrLogin(context, true);
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _push = true;
  final Map<String, bool> _settings = {
    '予約のリマインド': true,
    'お気に入り店舗の空き情報': true,
    'お気に入りキャストの出勤': true,
    'キャンペーン・お知らせ': false,
    'クーポン・特典': true,
    '重要なお知らせ': true,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF050505),
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  '通知設定',
                  style: TextStyle(
                    color: Color(0xFFF1D084),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFF1D084),
                      size: 30,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFF1D084),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
              children: [
                _pushSummary(),
                const SizedBox(height: 12),
                _notificationGroup('予約・注文', ['予約のリマインド']),
                _notificationGroup('お気に入り', ['お気に入り店舗の空き情報', 'お気に入りキャストの出勤']),
                _notificationGroup('キャンペーン', ['キャンペーン・お知らせ']),
                _notificationGroup('その他', ['重要なお知らせ']),
              ],
            ),
          ),
          FooterNavigation(
            activeIndex: 4,
            onItemTap: (index) => _handleDetailFooterNavigation(
              context,
              index,
              AppSession.currentArea,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _pushSummary() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF111110),
      border: Border.all(color: const Color(0xFFB9853E)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD7B56D)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFFF1D084),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'プッシュ通知',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '予約やお気に入りの最新情報をお知らせします',
                style: TextStyle(color: Color(0xFFAAA7A1), fontSize: 8),
              ),
            ],
          ),
        ),
        Switch(
          value: _push,
          activeColor: const Color(0xFFF1D084),
          activeTrackColor: const Color(0xFF8F6B32),
          onChanged: (value) => setState(() => _push = value),
        ),
      ],
    ),
  );

  Widget _notificationGroup(String title, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF1D084),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111110),
            border: Border.all(color: const Color(0xFF3D3A35)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -3),
                  title: Text(
                    items[i],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Switch(
                    value: _settings[items[i]] ?? false,
                    activeColor: const Color(0xFFF1D084),
                    activeTrackColor: const Color(0xFF8F6B32),
                    onChanged: (value) =>
                        setState(() => _settings[items[i]] = value),
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(height: 1, color: Color(0xFF302C27)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  late Future<List<CouponData>> _future = CouponApi().fetchCoupons(
    token: AppSession.token,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'クーポン',
                    style: TextStyle(
                      color: Color(0xFFF1D084),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFFF1D084),
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<CouponData>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF1D084),
                      ),
                    );
                  final coupons = snapshot.data ?? const <CouponData>[];
                  if (coupons.isEmpty) return const _CouponEmptyState();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: coupons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _CouponCard(coupon: coupons[index]),
                  );
                },
              ),
            ),
            FooterNavigation(
              activeIndex: 4,
              onItemTap: (index) => _handleDetailFooterNavigation(
                context,
                index,
                AppSession.currentArea,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon});
  final CouponData coupon;

  @override
  Widget build(BuildContext context) {
    final used = coupon.status != 'available';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111110),
        border: Border.all(
          color: used ? const Color(0xFF3A3835) : const Color(0xFF9A7134),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: used ? const Color(0xFF292827) : const Color(0xFF2B2112),
              borderRadius: BorderRadius.circular(5),
            ),
            child: coupon.logoImage.isNotEmpty
                ? Image.network(
                    _resolvePlanImageUrl(coupon.logoImage),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _couponDiscountMark(used),
                  )
                : _couponDiscountMark(used),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.name,
                  style: TextStyle(
                    color: used ? const Color(0xFF9A9894) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (coupon.description.isNotEmpty)
                  Text(
                    coupon.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAA7A1),
                      fontSize: 9,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  '有効期限：${coupon.expireTime.isEmpty ? '-' : coupon.expireTime}',
                  style: TextStyle(
                    color: used
                        ? const Color(0xFF74716D)
                        : const Color(0xFFD7B56D),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            used ? Icons.check_circle_outline : Icons.confirmation_num_outlined,
            color: used ? const Color(0xFF77746E) : const Color(0xFFF1D084),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _couponDiscountMark(bool used) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        coupon.discountType == 'percent'
            ? '${coupon.discountValue}%'
            : '¥${coupon.discountValue}',
        style: TextStyle(
          color: used ? const Color(0xFF888783) : const Color(0xFFF1D084),
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        coupon.discountType == 'percent' ? 'OFF' : '割引',
        style: const TextStyle(color: Color(0xFFA9A39A), fontSize: 8),
      ),
    ],
  );
}

class _CouponEmptyState extends StatelessWidget {
  const _CouponEmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF211C15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.confirmation_num_outlined,
            color: Color(0xFFD7B56D),
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'クーポンはありません',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '現在利用できるクーポンはありません',
          style: TextStyle(color: Color(0xFF99958F), fontSize: 10),
        ),
      ],
    ),
  );
}

class ThreeDButton extends StatefulWidget {
  const ThreeDButton({
    super.key,
    required this.height,
    required this.fontSize,
    required this.textColor,
    required this.shadowColor,
    this.gradient,
    this.backgroundColor,
    this.label = '今すぐ予約',
    this.onTap,
  });

  final double height;
  final double fontSize;
  final Color textColor;
  final Color shadowColor;
  final Gradient? gradient;
  final Color? backgroundColor;
  final String label;
  final VoidCallback? onTap;

  @override
  State<ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<ThreeDButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (mounted) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(4);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap?.call();
      },
      onTapCancel: () => _setPressed(false),
      child: SizedBox(
        height: widget.height + 4,
        width: double.infinity,
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            offset: Offset(0, _pressed ? 0.12 : 0),
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              height: widget.height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                gradient: widget.gradient,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, _pressed ? 1 : 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: widget.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
