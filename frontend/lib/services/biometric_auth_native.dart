import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService()
    : _auth = LocalAuthentication(),
      _storage = const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _enabledKey = 'cabago_face_id_enabled';
  static const _tokenKey = 'cabago_face_id_token';

  Future<bool> isEnabled() async =>
      (await _storage.read(key: _enabledKey)) == 'true';

  Future<bool> enable(String token) async {
    final supported = await _auth.isDeviceSupported();
    if (!supported) return false;
    final authenticated = await _auth.authenticate(
      localizedReason: 'Face IDを使用してCaba Nightにログインします',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) return false;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _enabledKey, value: 'true');
    return true;
  }

  Future<void> disable() async {
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> restoreToken() async {
    if (!await isEnabled()) return null;
    final authenticated = await _auth.authenticate(
      localizedReason: 'Face IDを使用してCaba Nightにログインします',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) return null;
    return _storage.read(key: _tokenKey);
  }
}
