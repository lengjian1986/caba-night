enum AppEnvironment {
  dev,
  prod;

  static AppEnvironment fromName(String value) {
    return value == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;
  }
}

class AppConfig {
  const AppConfig._();

  static const _envName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const _devApiBaseUrlOverride = String.fromEnvironment('DEV_API_BASE_URL');
  static const _prodApiBaseUrl = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://api.cabago.example',
  );

  static AppEnvironment get environment => AppEnvironment.fromName(_envName);

  static String get apiBaseUrl {
    return environment == AppEnvironment.prod ? _prodApiBaseUrl : devApiBaseUrl;
  }

  static String get devApiBaseUrl {
    if (_devApiBaseUrlOverride.isNotEmpty) {
      return _devApiBaseUrlOverride;
    }

    final host = Uri.base.host;
    if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
      return 'http://$host:20221';
    }

    return 'http://127.0.0.1:20221';
  }
}
