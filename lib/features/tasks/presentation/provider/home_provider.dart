import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/cancel_task_notification.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/create_new_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/delete_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/get_all_tasks.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/schedule_task_notification.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_instance.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_template.dart';
import 'package:auto_admin_app/features/tasks/injection/home_injection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeNotifier extends _$HomeNotifier {
  late final CreateNewTask _createNewTask = ref.read(createNewTaskProvider);
  late final DeleteTask _deleteTask = ref.read(deleteTaskProvider);
  late final GetAllTasks _getAllTasks = ref.read(getAllTasksProvider);
  late final UpdateTaskTemplate _updateTaskTemplate =
      ref.read(updateTaskTemplateProvider);
  late final UpdateTaskInstance _updateTaskInstance =
      ref.read(updateTaskInstanceProvider);
  late final ScheduleTaskNotification scheduleTaskNotification =
      ref.read(scheduleTaskNotificationProvider);
  late final CancelTaskNotification cancelTaskNotification =
      ref.read(cancelTaskNotificationProvider);

  @override
  Future<List<Task>> build() async {
    listenDateChanges();
    return getTasks(ref.read(selectedDateProvider));
  }

  Future<List<Task>> getTasks(DateTime date) async {
    return _getAllTasks.call(date);
  }

  Future<void> refreshTasks(DateTime date) async {
    state = const AsyncLoading();
    try {
      final tasks = await getTasks(date);
      state = AsyncData(tasks);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createRecurringTask({
    required String title,
    required DateTime startDate,
    required TaskFrequency frequency,
    DateTime? reminderDate,
  }) async {
    state = const AsyncLoading();
    Task newTask = await _createNewTask.call(
      TaskData(
        title: title,
        startDate: startDate,
        frequency: frequency,
        priority: state.value == null ? 0 : state.value!.length,
      ),
    );
    List<Task> tasks = List<Task>.from(state.value ?? []);
    tasks.add(newTask);
    state = AsyncData(tasks);
    if (reminderDate != null) {
      newTask.reminderDate = reminderDate;
      await scheduleTaskNotification.call(newTask);
    }
  }

  Future<void> editRecurringTask({
    required String templateId,
    required String instanceId,
    required String title,
    required DateTime startDate,
    required TaskFrequency frequency,
    DateTime? reminderDate,
  }) async {
    state = const AsyncLoading();
    Task updatedTask = await _updateTaskTemplate.call(
      UpdateTaskTemplateData(
        templateId: templateId,
        title: title,
        startDate: startDate,
        frequency: frequency,
      ),
    );
    List<Task> tasks = List<Task>.from(state.value ?? []);
    int index = tasks.indexWhere((task) => task.instanceId == instanceId);
    tasks[index] = updatedTask;
    state = AsyncData(tasks);
    if (reminderDate != null) {
      updatedTask.copyWith(
        reminderDate: reminderDate,
      );
      await scheduleTaskNotification.call(updatedTask);
    }
  }

  Future<void> deleteRecurringTask({
    required String templateId,
    required String instanceId,
    required DeleteScope scope,
    DateTime? referenceDate,
  }) async {
    await _deleteTask.call(
      DeleteTaskData(
        templateId: templateId,
        instanceId: instanceId,
        scope: scope,
        referenceDate: referenceDate,
      ),
    );
    List<Task> tasks = List<Task>.from(state.value ?? []);
    tasks.removeWhere((task) => task.id == instanceId);
    state = AsyncData(tasks);
    await cancelTaskNotification(instanceId);
  }

  void listenDateChanges() {
    ref.listen(selectedDateProvider, (previous, next) {
      refreshTasks(next);
    });
  }

  Future<void> completeTask({
    required Task task,
  }) async {
    List<Task> tasks = List<Task>.from(state.value ?? []);
    int index = tasks.indexWhere((currentTask) => currentTask.id == task.id);
    tasks[index] = task.copyWith(completed: !task.completed);
    state = AsyncData(tasks);
    Task updatedTask = await _updateTaskInstance.call(
      UpdateTaskInstanceData(
        instanceId: task.instanceId,
        completed: !task.completed,
        completedAt: task.completed ? null : DateTime.now(),
        subtaskStates: task.subtasks ?? [],
      ),
    );
    if (updatedTask.completed != tasks[index].completed) {
      tasks[index] = task.copyWith(completed: updatedTask.completed);
      state = AsyncData(tasks);
    }
    if (updatedTask.completed) {
      await cancelTaskNotification(task.id);
    } else {
      await scheduleTaskNotification.call(task);
    }
  }

  Future<bool> checkNotificationPermission() async {
    final androidPlugin = ref
        .read(flutterLocalNotificationsProvider)
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }
}

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  void selectDate(DateTime date) {
    state = date;
  }
}
