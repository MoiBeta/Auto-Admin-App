import 'dart:async';
import 'dart:developer';

import 'package:auto_admin_app/core/errors/error_handler.dart';
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

  /// Debounce timer for subtask syncing. Resets on every subtask toggle.
  Timer? _subtaskSyncTimer;

  /// Task ID that has pending subtask changes.
  String? _pendingSyncTaskId;

  /// The original task before any optimistic changes (for revert on error).
  Task? _pendingSyncOriginalTask;

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
    List<String>? subtasks,
  }) async {
    state = const AsyncLoading();
    try {
      Task updatedTask = await _updateTask.call(
        UpdateTaskData(
          taskId: taskId,
          title: title,
          startDate: startDate,
          frequency: frequency,
          subTasks: subtasks,
        ),
      );
      List<Task> tasks = List<Task>.from(state.value ?? []);
      int index = tasks.indexWhere((task) => task.id == taskId);
      tasks[index] = updatedTask;
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

    // 2. Store original task for revert (only first time per debounce window)
    if (_pendingSyncTaskId != task.id) {
      _pendingSyncOriginalTask = task;
    }
    _pendingSyncTaskId = task.id;

    // 3. Reset the debounce timer — send the full list after user stops
    _subtaskSyncTimer?.cancel();
    _subtaskSyncTimer = Timer(
      const Duration(seconds: 1),
      () => _syncSubtasksToBackend(task.id, date),
    );
  }

  Future<void> _syncSubtasksToBackend(String taskId, DateTime date) async {
    final originalTask = _pendingSyncOriginalTask;
    _pendingSyncTaskId = null;
    _pendingSyncOriginalTask = null;

    // Get the current optimistic state of the task's subtasks
    final tasks = List<Task>.from(state.value ?? []);
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final currentTask = tasks[taskIndex];
    final subtaskStates = currentTask.subtasks!
        .map((s) => SubtaskState(
              sourceSubTaskId: s.id,
              completed: s.completed,
            ))
        .toList();

    try {
      final updatedTask = await ref.read(taskRepositoryProvider).syncSubtasks(
            taskId: taskId,
            subtasks: subtaskStates,
            date: date,
          );

      // Reconcile with backend truth
      final currentTasks = List<Task>.from(state.value ?? []);
      final currentIndex = currentTasks.indexWhere((t) => t.id == taskId);
      if (currentIndex != -1) {
        currentTasks[currentIndex] = updatedTask;
        state = AsyncData(currentTasks);
      }
    } catch (e, st) {
      // Revert to original task state on failure
      if (originalTask != null) {
        final revertTasks = List<Task>.from(state.value ?? []);
        final revertIndex = revertTasks.indexWhere((t) => t.id == taskId);
        if (revertIndex != -1) {
          revertTasks[revertIndex] = originalTask;
          state = AsyncData(revertTasks);
        }
      }
      ref.read(errorHandlerProvider).handle(e, st);
    }
  }

  Future<void> updateTaskPriorities({
    required int oldIndex,
    required int newIndex,
  }) async {
    final previousTasks = List<Task>.from(state.value ?? []);
    if (previousTasks.isEmpty) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

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
        ),
      );
    } catch (e, st) {
      log('Exception: $e stacktrace: $st');
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(previousTasks);
    }
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
