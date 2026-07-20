import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/repositories/push_token_repository.dart';
import 'package:mobile/services/push_notification_service.dart';

class FakeMessagingClient implements PushMessagingClient {
  String? token;
  PushRemoteMessage? initialMessage;
  bool foregroundOptionsSet = false;
  final tokenRefreshController = StreamController<String>.broadcast();
  final messageController = StreamController<PushRemoteMessage>.broadcast();
  final openedController = StreamController<PushRemoteMessage>.broadcast();

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Stream<PushRemoteMessage> get onMessage => messageController.stream;

  @override
  Stream<PushRemoteMessage> get onMessageOpenedApp => openedController.stream;

  @override
  Future<PushRemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> setForegroundPresentationOptions() async {
    foregroundOptionsSet = true;
  }

  Future<void> dispose() async {
    await tokenRefreshController.close();
    await messageController.close();
    await openedController.close();
  }
}

class FakePermissionClient implements PushPermissionClient {
  PushPermissionState permissionState = PushPermissionState.granted;
  int permissionRequests = 0;
  int batteryRequests = 0;

  @override
  Future<PushPermissionState> requestPermission() async {
    permissionRequests += 1;
    return permissionState;
  }

  @override
  Future<void> requestIgnoreBatteryOptimizations() async {
    batteryRequests += 1;
  }
}

class FakeLocalNotificationClient implements LocalNotificationClient {
  bool initialized = false;
  void Function(Map<String, dynamic> data)? onPayload;
  final createdChannels = <PushNotificationChannelConfig>[];
  final shownMessages = <PushRemoteMessage>[];

  @override
  Future<void> initialize({
    required void Function(Map<String, dynamic> data) onPayload,
  }) async {
    initialized = true;
    this.onPayload = onPayload;
  }

  @override
  Future<void> createChannel(PushNotificationChannelConfig config) async {
    createdChannels.add(config);
  }

  @override
  Future<void> showForegroundNotification(
    PushRemoteMessage message,
    PushNotificationChannelConfig config,
  ) async {
    shownMessages.add(message);
  }
}

class FakePushTokenApi implements PushTokenApi {
  int failuresBeforeSuccess = 0;
  final registrations = <PushTokenRegistration>[];
  final removedDeviceIds = <String>[];

  @override
  Future<void> registerToken(PushTokenRegistration registration) async {
    registrations.add(registration);
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw Exception('network');
    }
  }

  @override
  Future<void> removeToken(String deviceId) async {
    removedDeviceIds.add(deviceId);
  }
}

class MemoryPushTokenStore implements PushTokenStore {
  String deviceId = 'device-1';
  String? lastToken;
  int clears = 0;

  @override
  Future<String> getDeviceId() async => deviceId;

  @override
  Future<String?> getLastSentToken() async => lastToken;

  @override
  Future<void> saveLastSentToken(String token) async {
    lastToken = token;
  }

  @override
  Future<void> clearLastSentToken() async {
    clears += 1;
    lastToken = null;
  }
}

PushNotificationService buildService({
  FakeMessagingClient? messaging,
  FakePermissionClient? permissions,
  FakeLocalNotificationClient? localNotifications,
  FakePushTokenApi? api,
  MemoryPushTokenStore? store,
  List<Duration>? retryDelays,
  List<Duration>? recordedDelays,
}) {
  return PushNotificationService(
    messagingClient: messaging ?? FakeMessagingClient(),
    permissionClient: permissions ?? FakePermissionClient(),
    localNotifications: localNotifications ?? FakeLocalNotificationClient(),
    tokenApi: api ?? FakePushTokenApi(),
    tokenStore: store ?? MemoryPushTokenStore(),
    firebaseInitializer: () async => true,
    appVersionResolver: () async => '1.0.0+1',
    retryDelays: retryDelays ?? const [],
    delay: (delay) async {
      recordedDelays?.add(delay);
    },
  );
}

void main() {
  test('getToken returns token when Firebase provides it', () async {
    final messaging = FakeMessagingClient()..token = 'fcm-token';
    final service = buildService(messaging: messaging);

    await expectLater(service.getToken(), completion('fcm-token'));
  });

  test('getToken handles null token without crashing', () async {
    final service = buildService(messaging: FakeMessagingClient());

    await expectLater(service.getToken(), completion(isNull));
  });

  test('requestPermission maps granted, denied and permanent denial', () async {
    final permissions = FakePermissionClient();
    final service = buildService(permissions: permissions);

    permissions.permissionState = PushPermissionState.granted;
    expect(await service.requestPermission(), PushPermissionState.granted);

    permissions.permissionState = PushPermissionState.denied;
    expect(await service.requestPermission(), PushPermissionState.denied);

    permissions.permissionState = PushPermissionState.permanentlyDenied;
    expect(
      await service.requestPermission(),
      PushPermissionState.permanentlyDenied,
    );
  });

  test('sendTokenToBackend sends token only when it changed', () async {
    final messaging = FakeMessagingClient()..token = 'new-token';
    final api = FakePushTokenApi();
    final store = MemoryPushTokenStore()..lastToken = 'old-token';
    final service = buildService(messaging: messaging, api: api, store: store);

    final result = await service.sendTokenToBackend();

    expect(result, isTrue);
    expect(api.registrations, hasLength(1));
    expect(api.registrations.single.fcmToken, 'new-token');
    expect(api.registrations.single.deviceId, 'device-1');
    expect(api.registrations.single.appVersion, '1.0.0+1');
    expect(store.lastToken, 'new-token');
  });

  test(
    'sendTokenToBackend skips backend call when token is unchanged',
    () async {
      final messaging = FakeMessagingClient()..token = 'same-token';
      final api = FakePushTokenApi();
      final store = MemoryPushTokenStore()..lastToken = 'same-token';
      final service = buildService(
        messaging: messaging,
        api: api,
        store: store,
      );

      final result = await service.sendTokenToBackend();

      expect(result, isTrue);
      expect(api.registrations, isEmpty);
    },
  );

  test(
    'sendTokenToBackend applies finite exponential retry on network errors',
    () async {
      final messaging = FakeMessagingClient()..token = 'retry-token';
      final api = FakePushTokenApi()..failuresBeforeSuccess = 2;
      final delays = <Duration>[];
      final service = buildService(
        messaging: messaging,
        api: api,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
        recordedDelays: delays,
      );

      final result = await service.sendTokenToBackend();

      expect(result, isTrue);
      expect(api.registrations, hasLength(3));
      expect(delays, const [Duration(seconds: 1), Duration(seconds: 2)]);
    },
  );

  test(
    'sendTokenToBackend returns false after finite failed retries',
    () async {
      final messaging = FakeMessagingClient()..token = 'retry-token';
      final api = FakePushTokenApi()..failuresBeforeSuccess = 5;
      final service = buildService(
        messaging: messaging,
        api: api,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 2)],
      );

      final result = await service.sendTokenToBackend();

      expect(result, isFalse);
      expect(api.registrations, hasLength(3));
    },
  );

  test('listenTokenRefresh resends refreshed token to backend', () async {
    final messaging = FakeMessagingClient();
    final api = FakePushTokenApi();
    final service = buildService(messaging: messaging, api: api);

    service.listenTokenRefresh();
    messaging.tokenRefreshController.add('refreshed-token');
    await pumpEventQueue();

    expect(api.registrations.single.fcmToken, 'refreshed-token');
    await messaging.dispose();
  });

  test(
    'removeTokenOnLogout calls backend and clears persisted token',
    () async {
      final api = FakePushTokenApi();
      final store = MemoryPushTokenStore()..lastToken = 'saved-token';
      final service = buildService(api: api, store: store);

      await service.removeTokenOnLogout();

      expect(api.removedDeviceIds, ['device-1']);
      expect(store.lastToken, isNull);
      expect(store.clears, 1);
    },
  );

  test(
    'initialize creates notification channel before foreground display',
    () async {
      final messaging = FakeMessagingClient();
      final localNotifications = FakeLocalNotificationClient();
      final service = buildService(
        messaging: messaging,
        localNotifications: localNotifications,
      );

      await service.initialize();
      messaging.messageController.add(
        const PushRemoteMessage(
          title: 'Nuevo mensaje',
          body: 'Contenido',
          data: {'type': 'new_message'},
        ),
      );
      await pumpEventQueue();

      expect(localNotifications.initialized, isTrue);
      expect(
        localNotifications.createdChannels.single.id,
        'tf_push_high_importance',
      );
      expect(localNotifications.shownMessages.single.body, 'Contenido');
      await messaging.dispose();
    },
  );
}
