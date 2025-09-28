import 'dart:developer';

import 'package:auto_admin_app/features/tasks/data/datasources/notification_local_data_source.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationLocalDataSourceImpl(this.flutterLocalNotificationsPlugin);

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required TaskFrequency taskFrequency,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_channel',
        'Tasks',
        channelDescription: 'Recordatorios de tareas',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: taskFrequency == TaskFrequency.daily
            ? DateTimeComponents.time
            : taskFrequency == TaskFrequency.weekly
                ? DateTimeComponents.dayOfWeekAndTime
                : taskFrequency == TaskFrequency.weekly
                    ? DateTimeComponents.dateAndTime
                    : null,
      );
    } catch (e) {
      log('Exception scheduling reminder: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
