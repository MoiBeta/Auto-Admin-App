import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';

abstract class NotificationLocalDataSource {
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TaskFrequency taskFrequency,
    String? payload,
  });

  Future<void> cancelNotification(int id);
}
