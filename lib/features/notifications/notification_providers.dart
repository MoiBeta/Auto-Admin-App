import 'package:auto_admin_app/features/notifications/device_token_repository.dart';
import 'package:auto_admin_app/features/notifications/push_notification_service.dart';
import 'package:auto_admin_app/features/tasks/injection/home_injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (_) => PushNotificationService(),
);

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return DeviceTokenRepository(client);
});
