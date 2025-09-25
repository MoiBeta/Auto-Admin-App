import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/firestore_data_source.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/notification_local_data_source.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/notification_local_data_source_impl.dart';
import 'package:auto_admin_app/features/tasks/data/repositories/notification_repository_impl.dart';
import 'package:auto_admin_app/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/notification_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/cancel_task_notification.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/create_new_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/delete_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/get_all_tasks.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/schedule_task_notification.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_instance.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_template.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tasks Data Source which has all the logic to handle the tasks operations (get, delete, edit, etc)
Provider<TasksDataSource> taskDataSourceProvider =
    Provider<TasksDataSource>((_) => FirestoreDataSource());

/// Flutter local notification plugin provider which has all the logic to handle local notifications
final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((_) {
  throw UnimplementedError();
});

/// Tasks repository provider which uses the data source to translate the request to the domain's contract
Provider<TasksRepository> taskRepositoryProvider = Provider<TasksRepository>(
    (ref) => TaskRepositoryImpl(ref.watch(taskDataSourceProvider)));

/// Notification local data source that receives the local notification plugins and uses it to schedule notifications
final notificationLocalDataSourceProvider =
    Provider<NotificationLocalDataSource>(
  (ref) => NotificationLocalDataSourceImpl(
    ref.watch(flutterLocalNotificationsProvider),
  ),
);

/// Notification repository provider which uses the data source to translate the request to the domain's contract
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(notificationLocalDataSourceProvider),
  ),
);

/// Tasks use cases providers
Provider<CreateNewTask> createNewTaskProvider = Provider<CreateNewTask>(
    (ref) => CreateNewTask(ref.watch(taskRepositoryProvider)));

Provider<DeleteTask> deleteTaskProvider = Provider<DeleteTask>(
    (ref) => DeleteTask(ref.watch(taskRepositoryProvider)));

Provider<GetAllTasks> getAllTasksProvider = Provider<GetAllTasks>(
    (ref) => GetAllTasks(ref.watch(taskRepositoryProvider)));

Provider<UpdateTaskTemplate> updateTaskTemplateProvider =
    Provider<UpdateTaskTemplate>(
        (ref) => UpdateTaskTemplate(ref.watch(taskRepositoryProvider)));

Provider<UpdateTaskInstance> updateTaskInstanceProvider =
    Provider<UpdateTaskInstance>(
        (ref) => UpdateTaskInstance(ref.watch(taskRepositoryProvider)));

/// Notification use cases providers
Provider<ScheduleTaskNotification> scheduleTaskNotificationProvider =
    Provider<ScheduleTaskNotification>((ref) =>
        ScheduleTaskNotification(ref.watch(notificationRepositoryProvider)));

Provider<CancelTaskNotification> cancelTaskNotificationProvider =
    Provider<CancelTaskNotification>((ref) =>
        CancelTaskNotification(ref.watch(notificationRepositoryProvider)));
