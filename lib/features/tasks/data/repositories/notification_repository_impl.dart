import 'package:auto_admin_app/features/tasks/data/datasources/notification_local_data_source.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl(this.localDataSource);

  @override
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await localDataSource.scheduleNotification(
      id: id.hashCode,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
  }

  @override
  Future<void> cancelNotification(String id) async {
    await localDataSource.cancelNotification(id.hashCode);
  }
}
