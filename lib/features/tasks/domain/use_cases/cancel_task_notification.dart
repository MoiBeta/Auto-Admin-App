import 'package:auto_admin_app/features/tasks/domain/repository/notification_repository.dart';

class CancelTaskNotification {
  final NotificationRepository repository;

  CancelTaskNotification(this.repository);

  Future<void> call(String taskId) async {
    await repository.cancelNotification(taskId);
  }
}
