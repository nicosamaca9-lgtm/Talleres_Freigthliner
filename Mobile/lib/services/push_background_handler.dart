import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint(
      'INFO: FCM: Mensaje recibido en background. Tipo: ${message.data['type']}',
    );
  } catch (error) {
    debugPrint('INFO: FCM: Error en background handler: $error');
  }
}
