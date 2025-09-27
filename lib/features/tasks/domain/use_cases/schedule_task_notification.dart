import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/notification_repository.dart';

class ScheduleTaskNotification {
  final NotificationRepository repository;

  ScheduleTaskNotification(this.repository);

  Future<void> call(Task task) async {
    if (task.reminderDate!.isAfter(DateTime.now())) {
      await repository.scheduleNotification(
        id: task.id,
        title: "Tarea pendiente",
        body: task.title,
        scheduledDate: task.reminderDate!,
      );
    }
  }
}
