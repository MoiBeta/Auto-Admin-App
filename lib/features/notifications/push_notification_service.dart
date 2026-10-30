import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.messageId}');
}

class PushNotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Requests notification permissions from the user.
  Future<void> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      log('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('Error requesting notification permission: $e');
    }
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

  /// Emits a new FCM token whenever FCM rotates it.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Listens for messages received while the app is in the foreground, which
  /// the system does not display.
  void setupForegroundHandler(void Function(String text) onMessage) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground message received: ${message.messageId}');
      final notification = message.notification;
      final text = [notification?.title, notification?.body]
          .whereType<String>()
          .join(': ');
      if (text.isNotEmpty) onMessage(text);
    });
  }

  /// Listens for taps on a notification that bring the app back from the
  /// background. An app started by a tap already opens on today's tasks.
  void setupOpenedHandler(void Function() onOpened) {
    FirebaseMessaging.onMessageOpenedApp.listen((_) => onOpened());
  }

  /// Registers the top-level background message handler with FCM.
  static void setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
