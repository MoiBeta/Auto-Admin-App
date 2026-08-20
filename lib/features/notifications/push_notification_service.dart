import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');
}

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests notification permissions from the user.
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    log('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Retrieves the current FCM device token.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      log('FCM Token: $token');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listens for messages received while the app is in the foreground.
  void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground message received: ${message.messageId}');
    });
  }

  /// Registers the top-level background message handler with FCM.
  static void setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
