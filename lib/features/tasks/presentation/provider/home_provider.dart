import 'dart:async';
import 'dart:developer';

import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/core/time/device_timezone.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/create_new_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/delete_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/get_all_tasks.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/toggle_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_template.dart';
import 'package:auto_admin_app/features/tasks/injection/home_injection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeNotifier extends _$HomeNotifier {
  late final CreateNewTask _createNewTask = ref.read(createNewTaskProvider);
  late final DeleteTask _deleteTask = ref.read(deleteTaskProvider);
  late final GetAllTasks _getAllTasks = ref.read(getAllTasksProvider);
  late final UpdateTask _updateTask = ref.read(updateTaskProvider);
  late final ToggleTask _toggleTask = ref.read(toggleTaskProvider);

  /// Pending subtask syncs, one per task and day, so toggling subtasks of
  /// another task or day does not cancel a pending sync.
  final Map<(String, DateTime), _SubtaskSync> _subtaskSyncs = {};

  /// Identifies the latest load, so a slower older one cannot overwrite it.
  int _latestLoad = 0;
  bool _isLoadingTasks = false;

  @override
  Future<List<Task>> build() async {
    listenDateChanges();
    return getTasks(ref.read(selectedDateProvider));
  }

  Future<List<Task>> getTasks(DateTime date) async {
    final tasks = await _getAllTasks.call(date);
    return tasks.map((task) => _withPendingToggles(task, date)).toList();
  }

  /// Toggles not saved yet are newer than what the backend just returned.
  Task _withPendingToggles(Task task, DateTime date) {
    final sync = _subtaskSyncs[(task.id, date)];
    final current = task.subtasks ?? [];
    if (sync == null || current.isEmpty) return task;

    final subtasks = current
        .map((s) => s.copyWith(completed: sync.subtasks[s.id] ?? s.completed))
        .toList();
    return task.copyWith(
      subtasks: subtasks,
      completed: subtasks.every((s) => s.completed),
    );
  }

  Future<void> refreshTasks(DateTime date) async {
    final load = ++_latestLoad;
    _isLoadingTasks = true;
    state = const AsyncLoading();
    try {
      final tasks = await getTasks(date);
      if (load != _latestLoad) return;
      _isLoadingTasks = false;
      state = AsyncData(tasks);
    } catch (e, st) {
      if (load != _latestLoad) return;
      _isLoadingTasks = false;
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncError(e, st);
    }
  }

  Future<void> createTask({
    required String title,
    required DateTime startDate,
    required TaskFrequency frequency,
    DateTime? reminderDate,
    List<String>? subtasks,
  }) async {
    state = const AsyncLoading();
    List<Task> tasks = List<Task>.from(state.value ?? []);
    final int newPriority = tasks.isEmpty ? 100 : tasks.last.priority + 100;

    try {
      Task newTask = await _createNewTask.call(
        NewTaskData(
          title: title,
          startDate: startDate,
          frequency: frequency,
          priority: newPriority,
          subTasks: subtasks,
          reminderDate: reminderDate,
          timezone: reminderDate != null ? await deviceTimezone() : null,
        ),
      );
      tasks.add(newTask);
      state = AsyncData(tasks);
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(tasks);
    }
  }

  Future<void> editTask({
    required String taskId,
    required String title,
    required DateTime startDate,
    required TaskFrequency frequency,
    DateTime? reminderDate,
    bool removeReminder = false,
    DateTime? newStartDate,
    List<String>? subtasks,
  }) async {
    final previous =
        state.value?.where((task) => task.id == taskId).firstOrNull;
    state = const AsyncLoading();
    try {
      final selectedDate = ref.read(selectedDateProvider);
      Task updatedTask = await _updateTask.call(
        UpdateTaskData(
          taskId: taskId,
          title: title,
          startDate: startDate,
          frequency: frequency,
          subTasks: subtasks,
          reminderDate: reminderDate,
          removeReminder: removeReminder,
          timezone: reminderDate != null ? await deviceTimezone() : null,
          newStartDate: newStartDate,
          date: selectedDate,
        ),
      );
      // A new start day or frequency can move the task to other days: reload
      // the list instead of patching it.
      if (newStartDate != null || previous?.taskFrequency != frequency) {
        await refreshTasks(ref.read(selectedDateProvider));
        return;
      }
      List<Task> tasks = List<Task>.from(state.value ?? []);
      int index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1 && _isShowing(selectedDate)) tasks[index] = updatedTask;
      state = AsyncData(tasks);
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      // Restore previous state
      state = AsyncData(state.value ?? []);
    }
  }

  Future<void> deleteTask({
    required String taskId,
    required DeleteScope scope,
    DateTime? referenceDate,
  }) async {
    final previousTasks = List<Task>.from(state.value ?? []);
    try {
      await _deleteTask.call(
        DeleteTaskData(
          taskId: taskId,
          scope: scope,
          referenceDate: referenceDate,
        ),
      );
      List<Task> tasks = List<Task>.from(state.value ?? []);
      tasks.removeWhere((task) => task.id == taskId);
      // Nothing left to sync: the request would fail with a 404.
      _subtaskSyncs.removeWhere((key, sync) {
        if (key.$1 != taskId) return false;
        sync.timer?.cancel();
        return true;
      });
      state = AsyncData(tasks);
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(previousTasks);
    }
  }

  void listenDateChanges() {
    ref.listen(selectedDateProvider, (previous, next) {
      refreshTasks(next);
    });
  }

  Future<void> toggleTask({
    required Task task,
    required DateTime date,
  }) async {
    List<Task> tasks = List<Task>.from(state.value ?? []);
    int index = tasks.indexWhere((currentTask) => currentTask.id == task.id);
    if (index == -1) return;
    tasks[index] = task.copyWith(completed: !task.completed);
    state = AsyncData(tasks);
    try {
      Task updatedTask = await _toggleTask.call(
        ToggleTaskData(
          taskId: task.id,
          completedAt: date,
        ),
      );
      if (updatedTask.completed != tasks[index].completed) {
        tasks[index] = task.copyWith(completed: updatedTask.completed);
        state = AsyncData(tasks);
      }
    } catch (e, st) {
      // Revert optimistic update
      tasks[index] = task;
      state = AsyncData(tasks);
      ref.read(errorHandlerProvider).handle(e, st);
    }
  }

  Future<void> toggleSubtask(
      {required Task task,
      required Subtask subtask,
      required DateTime date}) async {
    // 1. Optimistic update: toggle the subtask immediately in UI
    final tasks = List<Task>.from(state.value ?? []);
    final taskIndex = tasks.indexWhere((t) => t.id == task.id);
    if (taskIndex == -1) return;

    final currentTask = tasks[taskIndex];
    final optimisticSubtasks = currentTask.subtasks!.map((s) {
      if (s.id == subtask.id) {
        return s.copyWith(completed: !s.completed);
      }
      return s;
    }).toList();

    final allCompleted = optimisticSubtasks.every((s) => s.completed);
    final optimisticTask = currentTask.copyWith(
      subtasks: optimisticSubtasks,
      completed: allCompleted,
    );

    tasks[taskIndex] = optimisticTask;
    state = AsyncData(tasks);

    // 2. Remember the confirmed state for revert (only when a sync starts)
    final sync = _subtaskSyncs.putIfAbsent(
      (task.id, date),
      () => _SubtaskSync(confirmedTask: currentTask),
    );
    sync.subtasks = {for (final s in optimisticSubtasks) s.id: s.completed};
    sync.hasUnsentChanges = true;

    // 3. Reset this task's debounce timer — send the full list after user stops
    sync.timer?.cancel();
    sync.timer = Timer(
      const Duration(seconds: 1),
      () => _syncSubtasksToBackend(task.id, date),
    );
  }

  Future<void> _syncSubtasksToBackend(String taskId, DateTime date) async {
    final sync = _subtaskSyncs[(taskId, date)];
    if (sync == null) return;
    sync.timer = null;

    // Only one request at a time per task: this one's completion sends the
    // changes made in the meantime, so requests cannot arrive out of order.
    if (sync.inFlight) return;

    // Send what the user toggled, not the state shown now: it may be another
    // day's by this time.
    final subtaskStates = sync.subtasks.entries
        .map((s) => SubtaskState(sourceSubTaskId: s.key, completed: s.value))
        .toList();

    sync.inFlight = true;
    sync.hasUnsentChanges = false;

    try {
      final updatedTask = await ref.read(taskRepositoryProvider).syncSubtasks(
            taskId: taskId,
            subtasks: subtaskStates,
            date: date,
          );
      sync.inFlight = false;
      sync.confirmedTask = updatedTask;

      // Reconcile with backend truth, unless the user toggled something else
      // meanwhile: that response is already outdated.
      if (!sync.hasUnsentChanges) {
        _subtaskSyncs.remove((taskId, date));
        if (_isShowing(date)) {
          // A load started before this save may bring the old state.
          if (_isLoadingTasks) {
            unawaited(refreshTasks(date));
          } else {
            _replaceTask(updatedTask);
          }
        }
      }
    } catch (e, st) {
      sync.inFlight = false;

      // Revert to the confirmed state on failure. With newer changes pending,
      // their sync carries the full list and retries this one too.
      if (!sync.hasUnsentChanges) {
        _subtaskSyncs.remove((taskId, date));
        if (_isShowing(date)) _replaceTask(sync.confirmedTask);
        ref.read(errorHandlerProvider).handle(e, st);
      }
    }

    // The debounce timer expired during the request, so nothing else will
    // send these changes.
    if (sync.hasUnsentChanges && sync.timer == null) {
      await _syncSubtasksToBackend(taskId, date);
    }
  }

  bool _isShowing(DateTime date) => ref.read(selectedDateProvider) == date;

  void _replaceTask(Task task) {
    final tasks = List<Task>.from(state.value ?? []);
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      state = AsyncData(tasks);
    }
  }

  Future<void> updateTaskPriorities({
    required int oldIndex,
    required int newIndex,
  }) async {
    final previousTasks = List<Task>.from(state.value ?? []);
    if (previousTasks.isEmpty) return;

    final tasks = List<Task>.from(previousTasks);
    final movedTask = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, movedTask);

    final before = newIndex > 0 ? tasks[newIndex - 1] : null;
    final after = newIndex < tasks.length - 1 ? tasks[newIndex + 1] : null;

    int newPriority;
    if (before != null && after != null) {
      newPriority = (before.priority + after.priority) ~/ 2;
    } else if (before == null && after != null) {
      newPriority = after.priority - 100;
    } else if (before != null && after == null) {
      newPriority = before.priority + 100;
    } else {
      newPriority = 100;
    }

    final updatedTask = movedTask.copyWith(priority: newPriority);
    tasks[newIndex] = updatedTask;

    state = AsyncData(tasks);

    try {
      await _updateTask.call(
        UpdateTaskData(
          taskId: updatedTask.id,
          title: updatedTask.title,
          startDate: updatedTask.startDate,
          frequency: updatedTask.taskFrequency,
          priority: newPriority,
          date: ref.read(selectedDateProvider),
        ),
      );
    } catch (e, st) {
      log('Exception: $e stacktrace: $st');
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(previousTasks);
    }
  }
}

/// Debounce and in-flight state of a task's subtask sync.
class _SubtaskSync {
  /// Last state known to be saved on the backend, for revert on error.
  Task confirmedTask;

  /// Latest completion state chosen by the user, by subtask ID.
  Map<String, bool> subtasks = {};

  Timer? timer;
  bool inFlight = false;

  /// Toggles not yet included in a request.
  bool hasUnsentChanges = false;

  _SubtaskSync({required this.confirmedTask});
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
