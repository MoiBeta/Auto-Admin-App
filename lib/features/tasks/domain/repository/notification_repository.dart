abstract class NotificationRepository {
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });

  Future<void> cancelNotification(String id);
}
