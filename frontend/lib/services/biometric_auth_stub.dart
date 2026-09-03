class BiometricAuthService {
  Future<bool> isEnabled() async => false;

  Future<bool> enable(String token) async => false;

  Future<void> disable() async {}

  Future<String?> restoreToken() async => null;
}
