import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/network/interceptors/auth_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/error_interceptor.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/habits_remote_data_source.dart';
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
import 'package:auto_admin_app/features/tasks/domain/use_cases/toggle_sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/toggle_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_template.dart';
import 'package:auto_admin_app/global/di/global_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final habitsBaseUrlProvider =
    Provider<String>((ref) => dotenv.env['HABITS_BASE_URL'] ?? '');

final habitsDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(habitsBaseUrlProvider);
  final dio = Dio(BaseOptions(baseUrl: baseUrl));
  final tokenManager = ref.watch(tokenManagerProvider);
  final refreshDio = ref.watch(refreshDioProvider);
  dio.interceptors.addAll([
    AuthInterceptor(
        tokenManager: tokenManager, refreshDio: refreshDio, requestDio: dio),
    ErrorInterceptor(),
  ]);
  return dio;
});

final dioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(habitsDioProvider);
  return DioClient(dio);
});

Provider<TasksDataSource> taskDataSourceProvider = Provider<TasksDataSource>(
    (ref) => HabitsRemoteDataSource(client: ref.watch(dioClientProvider)));

final flutterLocalNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>((_) {
  throw UnimplementedError();
});

Provider<TasksRepository> taskRepositoryProvider = Provider<TasksRepository>(
    (ref) => TaskRepositoryImpl(ref.watch(taskDataSourceProvider)));

final notificationLocalDataSourceProvider =
    Provider<NotificationLocalDataSource>(
  (ref) => NotificationLocalDataSourceImpl(
    ref.watch(flutterLocalNotificationsProvider),
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    ref.watch(notificationLocalDataSourceProvider),
  ),
);

Provider<CreateNewTask> createNewTaskProvider = Provider<CreateNewTask>(
    (ref) => CreateNewTask(ref.watch(taskRepositoryProvider)));

Provider<DeleteTask> deleteTaskProvider = Provider<DeleteTask>(
    (ref) => DeleteTask(ref.watch(taskRepositoryProvider)));

Provider<GetAllTasks> getAllTasksProvider = Provider<GetAllTasks>(
    (ref) => GetAllTasks(ref.watch(taskRepositoryProvider)));

Provider<UpdateTask> updateTaskProvider = Provider<UpdateTask>(
    (ref) => UpdateTask(ref.watch(taskRepositoryProvider)));

Provider<ToggleTask> toggleTaskProvider = Provider<ToggleTask>(
    (ref) => ToggleTask(ref.watch(taskRepositoryProvider)));

Provider<ToggleSubTask> toggleSubTaskProvider = Provider<ToggleSubTask>(
    (ref) => ToggleSubTask(ref.watch(taskRepositoryProvider)));

Provider<ScheduleTaskNotification> scheduleTaskNotificationProvider =
    Provider<ScheduleTaskNotification>((ref) =>
        ScheduleTaskNotification(ref.watch(notificationRepositoryProvider)));

Provider<CancelTaskNotification> cancelTaskNotificationProvider =
    Provider<CancelTaskNotification>((ref) =>
        CancelTaskNotification(ref.watch(notificationRepositoryProvider)));
