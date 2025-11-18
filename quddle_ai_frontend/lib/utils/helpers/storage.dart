import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';

  static Future<void> saveSession({
    required String accessToken,
    required String userId,
    String? email,
    String? name,
    String? refreshToken,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    if (refreshToken != null) await _storage.write(key: keyRefreshToken, value: refreshToken);
    await _storage.write(key: keyUserId, value: userId);
    if (email != null) await _storage.write(key: keyUserEmail, value: email);
    if (name != null) await _storage.write(key: keyUserName, value: name);
  }

  static Future<String?> readToken() async {
    return _storage.read(key: keyAccessToken);
  }

  static Future<String?> readRefreshToken() async {
    return _storage.read(key: keyRefreshToken);
  }

  static Future<String?> readUserId() async {
    return _storage.read(key: keyUserId);
  }

  static Future<void> clear() async {
    await _storage.delete(key: keyAccessToken);
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keyUserId);
    await _storage.delete(key: keyUserEmail);
    await _storage.delete(key: keyUserName);
  }
}



