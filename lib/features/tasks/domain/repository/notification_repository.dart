import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';

abstract class NotificationRepository {
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TaskFrequency taskFrequency,
  });

  Future<void> cancelNotification(String id);
}
