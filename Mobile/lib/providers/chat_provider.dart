import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message_model.dart';
import '../models/message_status.dart';
import '../core/storage/secure_storage.dart';
import '../core/network/api_client.dart';

typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

class ChatProvider extends ChangeNotifier {
  ChatProvider({Dio? httpClient, WebSocketConnector? webSocketConnector})
    : _httpClient = httpClient ?? apiClient,
      _webSocketConnector =
          webSocketConnector ?? ((uri) => WebSocketChannel.connect(uri));

  final Dio _httpClient;
  final WebSocketConnector _webSocketConnector;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String? _deviceId;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _reconnectEnabled = true;
  bool get isConnected => _isConnected;

  // Lista de mensajes de la conversación activa
  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  // Contadores de no leídos por contacto
  final Map<int, int> _unreadCounts = {};
  int get totalUnread => _unreadCounts.values.fold(0, (a, b) => a + b);
  int unreadFor(int contactId) => _unreadCounts[contactId] ?? 0;

  // Estado de carga del historial
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;
  bool _hasMoreHistory = true;
  bool get hasMoreHistory => _hasMoreHistory;

  // ID del contacto activo
  dynamic _activeContactId;

  // Reconexión
  int _retrySeconds = 1;
  Timer? _retryTimer;

  // Paginación
  static const int _pageSize = 20;

  // --- Compatibilidad con dashboard_header.dart ---
  int get unreadCount => totalUnread;

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    _reconnectEnabled = true;
    _retryTimer?.cancel();

    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        _isConnecting = false;
        return;
      }

      final wsUrl = ApiClient.baseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('/api/v1', '/api/v1/chat/ws');
      _deviceId = await SecureStorage.getDeviceId();
      final uri = Uri.parse(
        wsUrl,
      ).replace(queryParameters: {'token': token, 'device_id': _deviceId!});

      _channel = _webSocketConnector(uri);
      _isConnected = true;
      _isConnecting = false;
      _retrySeconds = 1; // Reset backoff en conexión exitosa
      notifyListeners();
      unawaited(loadUnreadCounts());

      _subscription = _channel?.stream.listen(
        (data) {
          handleSocketData(data);
        },
        onDone: () {
          _handleSocketClosed();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleSocketClosed();
        },
      );
      if (_activeContactId != null) {
        _sendChatPresenceOpened(_activeContactId);
      }
    } catch (e) {
      _isConnecting = false;
      debugPrint('Error connecting to WebSocket: $e');
      _scheduleReconnect();
    }
  }

  @visibleForTesting
  void handleSocketData(dynamic data) {
    try {
      final decoded = data is String ? jsonDecode(data) : data;
      if (decoded is! Map) return;

      _handleSocketPayload(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('Error parsing chat socket payload: $e');
    }
  }

  void _handleSocketPayload(Map<String, dynamic> decoded) {
    if (decoded.containsKey('error')) {
      debugPrint('Chat error: ${decoded['error']}');
      return;
    }

    if (decoded['type'] == 'message_delivered') {
      final messageId = _parseMessageId(decoded['message_id']);
      if (messageId != null) {
        applyMessageDelivered(
          messageId,
          deliveredAt: _parseOptionalString(decoded['delivered_at']),
        );
      }
      return;
    }

    if (decoded['type'] == 'message_read') {
      final messageId = _parseMessageId(decoded['message_id']);
      if (messageId != null) {
        applyMessageRead(
          messageId,
          readAt: _parseOptionalString(decoded['read_at']),
        );
      }
      return;
    }

    final message = MessageModel.fromJson(decoded);

    if (_activeContactId == message.senderId ||
        _activeContactId == message.receiverId ||
        _activeContactId == 'admin') {
      final optimisticIndex = _messages.indexWhere(
        (m) =>
            m.id < 0 &&
            m.content == message.content &&
            m.senderId == message.senderId,
      );

      if (optimisticIndex != -1) {
        final newMessages = List<MessageModel>.from(_messages);
        newMessages[optimisticIndex] = message;
        _messages = newMessages;
      } else if (!_messages.any((m) => m.id == message.id)) {
        _messages = [message, ..._messages];
      }
    } else {
      _unreadCounts[message.senderId] =
          (_unreadCounts[message.senderId] ?? 0) + 1;
    }

    notifyListeners();
  }

  void _handleSocketClosed() {
    _subscription = null;
    _channel = null;
    _deviceId = null;
    _isConnecting = false;

    if (_isConnected) {
      _isConnected = false;
      notifyListeners();
    }

    if (_reconnectEnabled) {
      _scheduleReconnect();
    }
  }

  List<int> get messageIds =>
      _messages.map((message) => message.id).toList(growable: false);

  MessageModel? messageById(int messageId) {
    for (final message in _messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  void applyMessageRead(int messageId, {String? readAt}) {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) return;

    final current = _messages[index];
    final effectiveReadAt =
        readAt ?? current.readAt ?? DateTime.now().toUtc().toIso8601String();
    if (current.isRead == true &&
        current.readAt == effectiveReadAt &&
        current.apiStatus == MessageStatus.read.apiValue) {
      return;
    }

    final updatedMessages = List<MessageModel>.from(_messages);
    updatedMessages[index] = current.copyWith(
      isRead: true,
      readAt: effectiveReadAt,
      apiStatus: MessageStatus.read.apiValue,
    );
    _messages = updatedMessages;
    notifyListeners();
  }

  void applyMessageDelivered(int messageId, {String? deliveredAt}) {
    final index = _messages.indexWhere((message) => message.id == messageId);
    if (index == -1) return;

    final current = _messages[index];
    if (current.status == MessageStatus.read) return;

    final effectiveDeliveredAt =
        deliveredAt ??
        current.deliveredAt ??
        DateTime.now().toUtc().toIso8601String();
    if (current.status == MessageStatus.delivered &&
        current.deliveredAt == effectiveDeliveredAt) {
      return;
    }

    final updatedMessages = List<MessageModel>.from(_messages);
    updatedMessages[index] = current.copyWith(
      deliveredAt: effectiveDeliveredAt,
      apiStatus: MessageStatus.delivered.apiValue,
    );
    _messages = updatedMessages;
    notifyListeners();
  }

  int? _parseMessageId(dynamic rawValue) {
    if (rawValue is int) return rawValue;
    if (rawValue is num) return rawValue.toInt();
    if (rawValue is String) return int.tryParse(rawValue);
    return null;
  }

  String? _parseOptionalString(dynamic rawValue) {
    if (rawValue == null) return null;
    if (rawValue is String) return rawValue.isEmpty ? null : rawValue;
    return rawValue.toString();
  }

  @visibleForTesting
  void replaceMessagesForTesting(List<MessageModel> messages) {
    _messages = List<MessageModel>.from(messages);
    notifyListeners();
  }

  Future<void> loadUnreadCounts() async {
    try {
      final response = await _httpClient.get('/chat/unread-counts');
      if (response.statusCode != 200) return;

      final data = response.data;
      if (data is! Map) return;

      final rawCounts = data['counts'];
      if (rawCounts is! List) return;

      final nextCounts = <int, int>{};
      for (final item in rawCounts) {
        if (item is! Map) continue;

        final contactId = _parseMessageId(item['contact_id']);
        final unreadCount = _parseMessageId(item['unread_count']);
        if (contactId == null || unreadCount == null || unreadCount <= 0) {
          continue;
        }

        nextCounts[contactId] = unreadCount;
      }

      _unreadCounts
        ..clear()
        ..addAll(nextCounts);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread chat counts: $e');
    }
  }

  Future<void> markConversationRead(dynamic contactId) async {
    try {
      final encodedContactId = Uri.encodeComponent(contactId.toString());
      await _httpClient.patch('/chat/conversations/$encodedContactId/read');
    } catch (e) {
      debugPrint('Error marking chat conversation as read: $e');
    }
  }

  void _scheduleReconnect() {
    if (!_reconnectEnabled) return;

    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: _retrySeconds), () {
      _retrySeconds = (_retrySeconds * 2).clamp(1, 30).toInt();
      connect();
    });
  }

  Future<void> setActiveContact(dynamic contactId) async {
    _activeContactId = contactId;
    if (contactId == null) {
      _sendChatPresenceClosed();
    } else {
      _sendChatPresenceOpened(contactId);
    }

    var shouldMarkRead = false;

    if (contactId != null) {
      if (contactId is int) {
        shouldMarkRead = (_unreadCounts.remove(contactId) ?? 0) > 0;
      } else if (contactId.toString().toLowerCase() == 'admin') {
        shouldMarkRead = _unreadCounts.isNotEmpty;
        _unreadCounts.clear();
      }
    }
    notifyListeners();

    if (shouldMarkRead) {
      await markConversationRead(contactId);
    }
  }

  void _sendChatPresenceOpened(dynamic contactId) {
    _sendControlPayload({
      'type': 'chat_opened',
      'contact_id': contactId.toString(),
    });
  }

  void _sendChatPresenceClosed() {
    _sendControlPayload({'type': 'chat_closed'});
  }

  void _sendControlPayload(Map<String, dynamic> payload) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(payload));
  }

  Future<void> loadHistory(dynamic contactId) async {
    _messages = [];
    _hasMoreHistory = true;
    _isLoadingHistory = true;
    _activeContactId = contactId;
    notifyListeners();

    try {
      final response = await _httpClient.get(
        '/chat/history/$contactId',
        queryParameters: {'skip': 0, 'limit': _pageSize},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _messages = data.map((e) => MessageModel.fromJson(e)).toList();
        _hasMoreHistory = data.length >= _pageSize;
      }
    } catch (e) {
      debugPrint('Error fetching chat history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHistory(dynamic contactId) async {
    if (_isLoadingHistory || !_hasMoreHistory) return;
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final response = await _httpClient.get(
        '/chat/history/$contactId',
        queryParameters: {'skip': _messages.length, 'limit': _pageSize},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final older = data.map((e) => MessageModel.fromJson(e)).toList();
        _messages = [..._messages, ...older];
        _hasMoreHistory = data.length >= _pageSize;
      }
    } catch (e) {
      debugPrint('Error fetching more history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void sendMessage(dynamic receiverId, String content, {int? senderId}) {
    if (!_isConnected || _channel == null) return;
    if (content.length > 2000) return; // Límite de seguridad

    final payload = {'receiver_id': receiverId, 'content': content};

    // Inserción optimista para que el mensaje aparezca de inmediato en la UI
    if (senderId != null) {
      final tempMsg = MessageModel(
        id: -DateTime.now().millisecondsSinceEpoch, // ID temporal negativo
        senderId: senderId,
        receiverId: receiverId is int ? receiverId : 0,
        content: content,
        timestamp: DateTime.now().toIso8601String(),
        isRead: false,
        apiStatus: MessageStatus.sent.apiValue,
      );
      _messages = [tempMsg, ..._messages];
      notifyListeners();
    }

    _channel!.sink.add(jsonEncode(payload));
  }

  void disconnect() {
    _reconnectEnabled = false;
    _isConnecting = false;
    _retryTimer?.cancel();
    if (_activeContactId != null) {
      _sendChatPresenceClosed();
    }
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _deviceId = null;
    _isConnected = false;
    _messages.clear();
    _unreadCounts.clear();
    _activeContactId = null;
    notifyListeners();
  }
}
