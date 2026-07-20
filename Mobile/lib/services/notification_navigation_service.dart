import 'package:go_router/go_router.dart';

abstract class NotificationNavigator {
  void go(String location, {Object? extra});
}

class GoRouterNotificationNavigator implements NotificationNavigator {
  const GoRouterNotificationNavigator(this._router);

  final GoRouter _router;

  @override
  void go(String location, {Object? extra}) {
    _router.go(location, extra: extra);
  }
}

class NotificationDestination {
  const NotificationDestination({required this.location, this.extra});

  final String location;
  final Object? extra;
}

class NotificationNavigationService {
  const NotificationNavigationService(this._navigator);

  final NotificationNavigator _navigator;

  bool handleData(Map<String, dynamic> data) {
    final destination = destinationFor(data);
    if (destination == null) {
      return false;
    }

    _navigator.go(destination.location, extra: destination.extra);
    return true;
  }

  NotificationDestination? destinationFor(Map<String, dynamic> data) {
    final type = _stringValue(data['type']);

    switch (type) {
      case 'new_message':
        return _chatDestination(data);
      case 'order_assigned':
        return _orderDestination(data, basePath: '/mechanic/orders');
      case 'order_ready':
        return _orderDestination(data, basePath: '/client/orders');
      case 'booking_created':
        return _bookingDestination(data, basePath: '/admin/bookings');
      case 'booking_confirmed':
      case 'booking_rejected':
        return _bookingDestination(data, basePath: '/client/bookings');
      default:
        return null;
    }
  }

  NotificationDestination? _chatDestination(Map<String, dynamic> data) {
    final contactId = _typedId(data['contact_id']);
    if (contactId == null) {
      return null;
    }

    return NotificationDestination(
      location: '/chat',
      extra: {
        'contactId': contactId,
        'contactName': _stringValue(data['contact_name']) ?? 'Chat',
        if (_stringValue(data['chat_id']) != null)
          'chatId': _stringValue(data['chat_id']),
        if (_stringValue(data['message_id']) != null)
          'messageId': _stringValue(data['message_id']),
      },
    );
  }

  NotificationDestination? _orderDestination(
    Map<String, dynamic> data, {
    required String basePath,
  }) {
    final orderId = _typedId(data['order_id']);
    if (orderId == null) {
      return null;
    }

    return NotificationDestination(
      location: '$basePath/$orderId',
      extra: {'orderId': orderId, 'type': _stringValue(data['type'])},
    );
  }

  NotificationDestination? _bookingDestination(
    Map<String, dynamic> data, {
    required String basePath,
  }) {
    final bookingId = _typedId(data['booking_id']);
    if (bookingId == null) {
      return null;
    }

    return NotificationDestination(
      location: '$basePath/$bookingId',
      extra: {'bookingId': bookingId, 'type': _stringValue(data['type'])},
    );
  }

  Object? _typedId(Object? rawValue) {
    final value = _stringValue(rawValue);
    if (value == null) {
      return null;
    }

    return int.tryParse(value) ?? value;
  }

  String? _stringValue(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final value = rawValue.toString().trim();
    return value.isEmpty ? null : value;
  }
}
