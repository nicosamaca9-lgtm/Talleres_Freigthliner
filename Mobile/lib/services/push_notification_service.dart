import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/storage/secure_storage.dart';
import '../repositories/push_token_repository.dart';
import 'notification_navigation_service.dart';

enum PushPermissionState { granted, denied, permanentlyDenied }

class PushRemoteMessage {
  const PushRemoteMessage({this.title, this.body, required this.data});

  factory PushRemoteMessage.fromFirebase(RemoteMessage message) {
    return PushRemoteMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: Map<String, dynamic>.from(message.data),
    );
  }

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

class PushNotificationChannelConfig {
  const PushNotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

abstract class PushMessagingClient {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<PushRemoteMessage> get onMessage;
  Stream<PushRemoteMessage> get onMessageOpenedApp;
  Future<PushRemoteMessage?> getInitialMessage();
  Future<void> setForegroundPresentationOptions();
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  FirebaseMessaging get _client => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<String?> getToken() => _client.getToken();

  @override
  Stream<String> get onTokenRefresh => _client.onTokenRefresh;

  @override
  Stream<PushRemoteMessage> get onMessage =>
      FirebaseMessaging.onMessage.map(PushRemoteMessage.fromFirebase);

  @override
  Stream<PushRemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(PushRemoteMessage.fromFirebase);

  @override
  Future<PushRemoteMessage?> getInitialMessage() async {
    final message = await _client.getInitialMessage();
    return message == null ? null : PushRemoteMessage.fromFirebase(message);
  }

  @override
  Future<void> setForegroundPresentationOptions() {
    return _client.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

abstract class PushPermissionClient {
  Future<PushPermissionState> requestPermission();
  Future<void> requestIgnoreBatteryOptimizations();
}

class PermissionHandlerPushPermissionClient implements PushPermissionClient {
  @override
  Future<PushPermissionState> requestPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return PushPermissionState.granted;
    }

    final currentStatus = await Permission.notification.status;
    if (currentStatus.isGranted) {
      return PushPermissionState.granted;
    }
    if (currentStatus.isPermanentlyDenied) {
      return PushPermissionState.permanentlyDenied;
    }

    final nextStatus = await Permission.notification.request();
    if (nextStatus.isGranted) {
      return PushPermissionState.granted;
    }
    if (nextStatus.isPermanentlyDenied) {
      return PushPermissionState.permanentlyDenied;
    }
    return PushPermissionState.denied;
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (error) {
      debugPrint(
        'INFO: FCM: No se pudo solicitar exclusion de optimizacion de bateria: $error',
      );
    }
  }
}

abstract class LocalNotificationClient {
  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onPayload,
  });
  Future<void> createChannel(PushNotificationChannelConfig config);
  Future<void> showForegroundNotification(
    PushRemoteMessage message,
    PushNotificationChannelConfig config,
  );
}

class FlutterLocalNotificationClient implements LocalNotificationClient {
  FlutterLocalNotificationClient({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onPayload,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            onPayload(Map<String, dynamic>.from(decoded));
          }
        } catch (error) {
          debugPrint('INFO: FCM: Payload local invalido: $error');
        }
      },
    );
  }

  @override
  Future<void> createChannel(PushNotificationChannelConfig config) async {
    const importance = Importance.high;
    final androidChannel = AndroidNotificationChannel(
      config.id,
      config.name,
      description: config.description,
      importance: importance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  @override
  Future<void> showForegroundNotification(
    PushRemoteMessage message,
    PushNotificationChannelConfig config,
  ) async {
    final title = message.title ?? 'TF Centro Automotriz';
    final body = message.body ?? '';
    if (body.isEmpty && message.data.isEmpty) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        config.id,
        config.name,
        channelDescription: config.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }
}

abstract class PushTokenStore {
  Future<String> getDeviceId();
  Future<String?> getLastSentToken();
  Future<void> saveLastSentToken(String token);
  Future<void> clearLastSentToken();
}

class SecurePushTokenStore implements PushTokenStore {
  @override
  Future<String> getDeviceId() => SecureStorage.getDeviceId();

  @override
  Future<String?> getLastSentToken() => SecureStorage.getLastFcmToken();

  @override
  Future<void> saveLastSentToken(String token) {
    return SecureStorage.saveLastFcmToken(token);
  }

  @override
  Future<void> clearLastSentToken() => SecureStorage.deleteLastFcmToken();
}

class PushNotificationService {
  PushNotificationService({
    PushMessagingClient? messagingClient,
    PushPermissionClient? permissionClient,
    LocalNotificationClient? localNotifications,
    PushTokenApi? tokenApi,
    PushTokenStore? tokenStore,
    Future<bool> Function()? firebaseInitializer,
    Future<String?> Function()? appVersionResolver,
    Future<void> Function(Duration delay)? delay,
    List<Duration>? retryDelays,
  }) : _messagingClient = messagingClient ?? FirebasePushMessagingClient(),
       _permissionClient =
           permissionClient ?? PermissionHandlerPushPermissionClient(),
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationClient(),
       _tokenApi = tokenApi ?? DioPushTokenApi(),
       _tokenStore = tokenStore ?? SecurePushTokenStore(),
       _firebaseInitializer =
           firebaseInitializer ?? PushNotificationService.initializeFirebase,
       _appVersionResolver = appVersionResolver ?? _resolveAppVersion,
       _delay = delay ?? Future<void>.delayed,
       _retryDelays =
           retryDelays ??
           const [
             Duration(seconds: 1),
             Duration(seconds: 2),
             Duration(seconds: 4),
           ];

  static const channelConfig = PushNotificationChannelConfig(
    id: 'tf_push_high_importance',
    name: 'Notificaciones importantes',
    description: 'Mensajes, ordenes asignadas y ordenes listas para entrega.',
  );

  final PushMessagingClient _messagingClient;
  final PushPermissionClient _permissionClient;
  final LocalNotificationClient _localNotifications;
  final PushTokenApi _tokenApi;
  final PushTokenStore _tokenStore;
  final Future<bool> Function() _firebaseInitializer;
  final Future<String?> Function() _appVersionResolver;
  final Future<void> Function(Duration delay) _delay;
  final List<Duration> _retryDelays;

  NotificationNavigationService? _navigationService;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PushRemoteMessage>? _messageSubscription;
  StreamSubscription<PushRemoteMessage>? _messageOpenedSubscription;
  bool _initialized = false;

  static Future<bool> initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (error) {
      debugPrint('INFO: FCM: Firebase no se pudo inicializar: $error');
      return false;
    }
  }

  static Future<String?> _resolveAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  void configureNavigation(NotificationNavigationService navigationService) {
    _navigationService = navigationService;
  }

  Future<void> initialize({
    bool requestBatteryOptimizationExemption = false,
  }) async {
    if (_initialized) {
      return;
    }

    final firebaseReady = await _firebaseInitializer();
    if (!firebaseReady) {
      return;
    }

    await _messagingClient.setForegroundPresentationOptions();
    await _localNotifications.initialize(onPayload: handleNotificationData);
    await _localNotifications.createChannel(channelConfig);

    _messageSubscription = _messagingClient.onMessage.listen((message) {
      unawaited(
        _localNotifications.showForegroundNotification(message, channelConfig),
      );
    });
    _messageOpenedSubscription = _messageOpenedStream().listen((message) {
      handleNotificationData(message.data);
    });

    final initialMessage = await _messagingClient.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationData(initialMessage.data);
    }

    listenTokenRefresh();
    if (requestBatteryOptimizationExemption) {
      await requestIgnoreBatteryOptimizations();
    }
    _initialized = true;
  }

  Stream<PushRemoteMessage> _messageOpenedStream() {
    return _messagingClient.onMessageOpenedApp;
  }

  Future<PushPermissionState> requestPermission() async {
    final state = await _permissionClient.requestPermission();
    debugPrint(
      'INFO: FCM: Estado permiso notificaciones Android: ${state.name}',
    );
    return state;
  }

  Future<void> requestIgnoreBatteryOptimizations() {
    return _permissionClient.requestIgnoreBatteryOptimizations();
  }

  Future<String?> getToken() async {
    try {
      final token = await _messagingClient.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('INFO: FCM: Token no disponible para este dispositivo.');
        return null;
      }
      debugPrint('DEBUG: FCM: Token local obtenido: ${_truncateToken(token)}');
      return token;
    } catch (error) {
      debugPrint('INFO: FCM: Error obteniendo token local: $error');
      return null;
    }
  }

  void listenTokenRefresh() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messagingClient.onTokenRefresh.listen((token) {
      debugPrint(
        'INFO: FCM: Token refrescado localmente: ${_truncateToken(token)}',
      );
      unawaited(sendTokenToBackend(token: token, force: true));
    });
  }

  Future<bool> sendTokenToBackend({String? token, bool force = false}) async {
    final effectiveToken = token ?? await getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      return false;
    }

    final lastSentToken = await _tokenStore.getLastSentToken();
    if (!force && lastSentToken == effectiveToken) {
      debugPrint('DEBUG: FCM: Token sin cambios, no se reenvia al backend.');
      return true;
    }

    final deviceId = await _tokenStore.getDeviceId();
    final appVersion = await _appVersionResolver();
    final registration = PushTokenRegistration(
      deviceId: deviceId,
      fcmToken: effectiveToken,
      platform: 'android',
      appVersion: appVersion,
    );

    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      try {
        await _tokenApi.registerToken(registration);
        await _tokenStore.saveLastSentToken(effectiveToken);
        debugPrint(
          'INFO: FCM: Token enviado al backend para dispositivo $deviceId. '
          'Token: ${_truncateToken(effectiveToken)}',
        );
        return true;
      } catch (error) {
        debugPrint(
          'INFO: FCM: Fallo registrando token en backend '
          '(intento ${attempt + 1}): $error',
        );
        if (attempt == _retryDelays.length) {
          return false;
        }
        await _delay(_retryDelays[attempt]);
      }
    }

    return false;
  }

  Future<void> syncTokenAfterLogin() async {
    await initialize();
    await requestPermission();
    await sendTokenToBackend();
    await requestIgnoreBatteryOptimizations();
  }

  Future<void> removeTokenOnLogout() async {
    try {
      final deviceId = await _tokenStore.getDeviceId();
      await _tokenApi.removeToken(deviceId);
      debugPrint('INFO: FCM: Token desasociado del backend para $deviceId.');
    } catch (error) {
      debugPrint('INFO: FCM: No se pudo desasociar token en logout: $error');
    } finally {
      await _tokenStore.clearLastSentToken();
    }
  }

  bool handleNotificationData(Map<String, dynamic> data) {
    final handled = _navigationService?.handleData(data) ?? false;
    if (!handled) {
      debugPrint('INFO: FCM: Payload sin navegacion conocida: $data');
    }
    return handled;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _messageSubscription = null;
    _messageOpenedSubscription = null;
    _initialized = false;
  }

  String _truncateToken(String token) {
    final length = token.length <= 24 ? token.length : 24;
    return '${token.substring(0, length)}...';
  }
}

final pushNotificationService = PushNotificationService();
