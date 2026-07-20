import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class PushTokenRegistration {
  const PushTokenRegistration({
    required this.deviceId,
    required this.fcmToken,
    required this.platform,
    this.appVersion,
  });

  final String deviceId;
  final String fcmToken;
  final String platform;
  final String? appVersion;

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'fcm_token': fcmToken,
    'platform': platform,
    if (appVersion != null) 'app_version': appVersion,
  };
}

abstract class PushTokenApi {
  Future<void> registerToken(PushTokenRegistration registration);
  Future<void> removeToken(String deviceId);
}

class DioPushTokenApi implements PushTokenApi {
  DioPushTokenApi({Dio? httpClient}) : _httpClient = httpClient ?? apiClient;

  final Dio _httpClient;

  @override
  Future<void> registerToken(PushTokenRegistration registration) async {
    await _httpClient.post(
      '/device-tokens/register',
      data: registration.toJson(),
    );
  }

  @override
  Future<void> removeToken(String deviceId) async {
    await _httpClient.delete('/device-tokens/$deviceId');
  }
}
