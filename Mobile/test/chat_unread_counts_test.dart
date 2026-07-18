import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/chat_provider.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeWebSocketSink implements WebSocketSink {
  final List<dynamic> addedPayloads = [];
  final Completer<void> _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

  @override
  void add(dynamic data) {
    addedPayloads.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final event in stream) {
      add(event);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}

class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeWebSocketChannel() : _streamController = StreamController<dynamic>();

  final StreamController<dynamic> _streamController;
  final FakeWebSocketSink fakeSink = FakeWebSocketSink();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  WebSocketSink get sink => fakeSink;

  @override
  Stream<dynamic> get stream => _streamController.stream;
}

Dio buildDio({List<String>? patchPaths}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'GET' && options.path == '/chat/unread-counts') {
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'total': 5,
                'counts': [
                  {'contact_id': 7, 'unread_count': 2},
                  {'contact_id': 9, 'unread_count': 3},
                ],
              },
            ),
          );
        }

        if (options.method == 'PATCH') {
          patchPaths?.add(options.path);
          return handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'updated_count': 1},
            ),
          );
        }

        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 404),
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final key = args['key'];

          if (call.method == 'read' && key == 'access_token') {
            return 'token-123';
          }
          if (call.method == 'read' && key == 'device_id') {
            return 'device-abc';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test('loadUnreadCounts hydrates grouped backend counts', () async {
    final provider = ChatProvider(httpClient: buildDio());

    await provider.loadUnreadCounts();

    expect(provider.totalUnread, 5);
    expect(provider.unreadFor(7), 2);
    expect(provider.unreadFor(9), 3);
  });

  test('new websocket message increments only the closed chat badge', () {
    final provider = ChatProvider(httpClient: buildDio());

    provider.handleSocketData(
      jsonEncode({
        'id': 101,
        'sender_id': 7,
        'receiver_id': 1,
        'content': 'Nuevo mensaje',
        'timestamp': '2026-07-17T15:10:00Z',
        'is_read': false,
        'status': 'sent',
      }),
    );

    expect(provider.unreadFor(7), 1);
    expect(provider.unreadFor(9), 0);
    expect(provider.totalUnread, 1);
  });

  test(
    'opening a chat clears its badge and calls bulk read endpoint',
    () async {
      final patchPaths = <String>[];
      final provider = ChatProvider(
        httpClient: buildDio(patchPaths: patchPaths),
      );

      provider.handleSocketData(
        jsonEncode({
          'id': 101,
          'sender_id': 7,
          'receiver_id': 1,
          'content': 'Nuevo mensaje',
          'timestamp': '2026-07-17T15:10:00Z',
          'is_read': false,
          'status': 'sent',
        }),
      );

      await provider.setActiveContact(7);

      expect(provider.unreadFor(7), 0);
      expect(provider.totalUnread, 0);
      expect(patchPaths, ['/chat/conversations/7/read']);
    },
  );

  test('websocket connection sends device presence for active chat', () async {
    final fakeChannel = FakeWebSocketChannel();
    Uri? capturedUri;
    final provider = ChatProvider(
      httpClient: buildDio(),
      webSocketConnector: (uri) {
        capturedUri = uri;
        return fakeChannel;
      },
    );

    await provider.connect();
    await provider.setActiveContact(7);
    await provider.setActiveContact(null);

    expect(capturedUri, isNotNull);
    expect(capturedUri!.queryParameters['token'], 'token-123');
    expect(capturedUri!.queryParameters['device_id'], 'device-abc');
    expect(
      fakeChannel.fakeSink.addedPayloads
          .map((payload) => jsonDecode(payload as String))
          .toList(),
      [
        {'type': 'chat_opened', 'contact_id': '7'},
        {'type': 'chat_closed'},
      ],
    );
  });
}
