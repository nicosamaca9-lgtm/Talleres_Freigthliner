import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _deviceIdKey = 'device_id';
  static const _lastFcmTokenKey = 'last_fcm_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<String> getDeviceId() async {
    final existingDeviceId = await _storage.read(key: _deviceIdKey);
    if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
      return existingDeviceId;
    }

    final generatedDeviceId = 'device-${DateTime.now().microsecondsSinceEpoch}';
    await _storage.write(key: _deviceIdKey, value: generatedDeviceId);
    return generatedDeviceId;
  }

  static Future<String?> getLastFcmToken() async {
    return await _storage.read(key: _lastFcmTokenKey);
  }

  static Future<void> saveLastFcmToken(String token) async {
    await _storage.write(key: _lastFcmTokenKey, value: token);
  }

  static Future<void> deleteLastFcmToken() async {
    await _storage.delete(key: _lastFcmTokenKey);
  }
}
