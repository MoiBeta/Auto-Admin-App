import 'dart:async';
import 'dart:developer';

import 'package:auto_admin_app/core/errors/error_handler.dart';
import 'package:auto_admin_app/core/time/device_timezone.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
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
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_provider.g.dart';

// The page offers a retry: don't keep the user waiting on automatic ones.
Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
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

  /// Deleted tasks that can still be restored, by task ID.
  final Map<String, _PendingDelete> _pendingDeletes = {};

  /// Longer than the snackbar offering to undo, so undoing is always possible.
  static const _undoDeleteWindow = Duration(seconds: 5);

  /// Pending task toggles, one per task and day.
  final Map<(String, DateTime), _ToggleSync> _toggleSyncs = {};
  bool _isLoadingTasks = false;

  @override
  Future<List<Task>> build() async {
    // This provider outlives the session: start over when the user changes.
    final userId = ref.watch(
      authNotifierProvider.select((auth) => auth.value?.credentials?.id),
    );

    listenDateChanges();

    final lifecycle = AppLifecycleListener(onHide: flushPendingChanges);
    ref.onDispose(() {
      lifecycle.dispose();
      for (final sync in _subtaskSyncs.values) {
        sync.timer?.cancel();
      }
      _subtaskSyncs.clear();
      for (final sync in _toggleSyncs.values) {
        sync.timer?.cancel();
      }
      _toggleSyncs.clear();
      for (final pending in _pendingDeletes.values) {
        pending.timer.cancel();
      }
      _pendingDeletes.clear();
      // A load in progress belongs to the previous session.
      _latestLoad++;
      _isLoadingTasks = false;
    });

    if (userId == null) return [];
    return getTasks(ref.read(selectedDateProvider));
  }

  Future<List<Task>> getTasks(DateTime date) async {
    final tasks = await _getAllTasks.call(date);
    return tasks
        .where((task) => !_pendingDeletes.containsKey(task.id))
        .map((task) => _withPendingToggles(task, date))
        .toList();
  }

  /// Toggles not saved yet are newer than what the backend just returned.
  Task _withPendingToggles(Task task, DateTime date) {
    final toggle = _toggleSyncs[(task.id, date)];
    if (toggle != null) task = task.copyWith(completed: toggle.wanted);

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
      if (!ref.mounted || load != _latestLoad) return;
      _isLoadingTasks = false;
      state = AsyncData(tasks);
    } catch (e, st) {
      if (!ref.mounted || load != _latestLoad) return;
      _isLoadingTasks = false;
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncError(e, st);
    }
  }

  /// Returns the new task, or null if it could not be created.
  Future<Task?> createTask({
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
      // Only the backend knows whether its schedule includes the selected day.
      await refreshTasks(ref.read(selectedDateProvider));
      return newTask;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      state = AsyncData(tasks);
      return null;
    }
  }

  /// Returns whether the task was saved.
  Future<bool> editTask({
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
        return true;
      }
      List<Task> tasks = List<Task>.from(state.value ?? []);
      int index = tasks.indexWhere((task) => task.id == taskId);
      if (index != -1 && _isShowing(selectedDate)) tasks[index] = updatedTask;
      state = AsyncData(tasks);
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      // Restore previous state
      state = AsyncData(state.value ?? []);
      return false;
    }
  }

  /// Hides the task now and deletes it when the undo window ends.
  void scheduleDelete(Task task) {
    final tasks = List<Task>.from(state.value ?? []);
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    tasks.removeAt(index);
    _pendingDeletes[task.id] = _PendingDelete(
      task: task,
      index: index,
      date: ref.read(selectedDateProvider),
      timer: Timer(_undoDeleteWindow, () => _commitDelete(task.id)),
    );
    state = AsyncData(tasks);
  }

  void undoDelete(String taskId) {
    final pending = _pendingDeletes[taskId];
    if (pending == null || pending.request != null) return;
    _pendingDeletes.remove(taskId);
    pending.timer.cancel();

    if (!_isShowing(pending.date)) return;
    final tasks = List<Task>.from(state.value ?? []);
    tasks.insert(pending.index.clamp(0, tasks.length), pending.task);
    state = AsyncData(tasks);
  }

  Future<void> _commitDelete(String taskId) {
    final pending = _pendingDeletes[taskId];
    if (pending == null) return Future.value();
    pending.timer.cancel();
    return pending.request ??= _sendDelete(taskId);
  }

  Future<void> _sendDelete(String taskId) async {
    final deleted = await deleteTask(taskId: taskId, scope: DeleteScope.all);
    if (!ref.mounted) return;
    _pendingDeletes.remove(taskId);
    // It is still on the backend: show it again.
    if (!deleted) await refreshTasks(ref.read(selectedDateProvider));
  }

  /// Returns whether the task was deleted.
  Future<bool> deleteTask({
    required String taskId,
    required DeleteScope scope,
    DateTime? referenceDate,
  }) async {
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
      return true;
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      return false;
    }
  }

  void listenDateChanges() {
    ref.listen(selectedDateProvider, (previous, next) {
      unawaited(flushPendingChanges());
      refreshTasks(next);
    });
  }

  /// Shows the change at once and sends it when the user stops tapping.
  ///
  /// The toggle endpoint flips the state, so only one request per task is sent
  /// at a time, and only when the state wanted differs from the saved one:
  /// tapping twice sends nothing.
  void toggleTask({
    required Task task,
    required DateTime date,
  }) {
    final sync = _toggleSyncs.putIfAbsent(
      (task.id, date),
      () => _ToggleSync(confirmed: task.completed),
    );
    sync.wanted = !sync.wanted;
    _patchTask(task.id, (t) => t.copyWith(completed: sync.wanted));

    sync.timer?.cancel();
    sync.timer = Timer(
      const Duration(seconds: 1),
      () => _sendToggle(task.id, date),
    );
  }

  Future<void> _sendToggle(String taskId, DateTime date) {
    final sync = _toggleSyncs[(taskId, date)];
    if (sync == null) return Future.value();
    sync.timer = null;

    // Its completion checks again what the user wants now.
    if (sync.inFlight) return sync.request;

    if (sync.wanted == sync.confirmed) {
      _toggleSyncs.remove((taskId, date));
      return Future.value();
    }
    return sync.request = _sendToggleRequest(taskId, date, sync);
  }

  Future<void> _sendToggleRequest(
    String taskId,
    DateTime date,
    _ToggleSync sync,
  ) async {
    sync.inFlight = true;
    try {
      final updatedTask = await _toggleTask.call(
        ToggleTaskData(taskId: taskId, completedAt: date),
      );
      if (!ref.mounted) return;
      sync.inFlight = false;
      if (updatedTask.completed == sync.confirmed) {
        // The backend did not flip it: trust it rather than ask again.
        _endToggleSync(taskId, date, sync);
        return;
      }
      sync.confirmed = updatedTask.completed;
    } catch (e, st) {
      if (!ref.mounted) return;
      sync.inFlight = false;
      _endToggleSync(taskId, date, sync);
      ref.read(errorHandlerProvider).handle(e, st);
      return;
    }

    // Taps made during the request whose debounce already expired.
    if (sync.timer == null) await _sendToggle(taskId, date);
  }

  /// Drops the taps not sent and shows the state saved on the backend.
  void _endToggleSync(String taskId, DateTime date, _ToggleSync sync) {
    sync.timer?.cancel();
    _toggleSyncs.remove((taskId, date));
    if (_isShowing(date)) {
      _patchTask(taskId, (t) => t.copyWith(completed: sync.confirmed));
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

  /// Sends the pending toggles, subtask changes and deletions now, and
  /// completes when they are saved or reverted.
  Future<void> flushPendingChanges() async {
    await Future.wait([
      ..._subtaskSyncs.entries.toList().map((entry) {
        entry.value.timer?.cancel();
        return _syncSubtasksToBackend(entry.key.$1, entry.key.$2);
      }),
      ..._toggleSyncs.entries.toList().map((entry) {
        entry.value.timer?.cancel();
        return _sendToggle(entry.key.$1, entry.key.$2);
      }),
      ..._pendingDeletes.keys.toList().map(_commitDelete),
    ]);
  }

  Future<void> _syncSubtasksToBackend(String taskId, DateTime date) {
    final sync = _subtaskSyncs[(taskId, date)];
    if (sync == null) return Future.value();
    sync.timer = null;

    // Only one request at a time per task: this one's completion sends the
    // changes made in the meantime, so requests cannot arrive out of order.
    if (sync.inFlight) return sync.request;

    return sync.request = _sendSubtasks(taskId, date, sync);
  }

  Future<void> _sendSubtasks(
    String taskId,
    DateTime date,
    _SubtaskSync sync,
  ) async {
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
      if (!ref.mounted) return;
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
      if (!ref.mounted) return;
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

  Future<void> _renumberPriorities(List<Task> ordered) async {
    final date = ref.read(selectedDateProvider);
    final renumbered = [
      for (final (i, task) in ordered.indexed)
        task.copyWith(priority: (i + 1) * 100),
    ];
    state = AsyncData(renumbered);

    try {
      for (final (i, task) in renumbered.indexed) {
        if (task.priority == ordered[i].priority) continue;
        await _updateTask.call(
          UpdateTaskData(
            taskId: task.id,
            title: task.title,
            startDate: task.startDate,
            frequency: task.taskFrequency,
            priority: task.priority,
            date: date,
          ),
        );
      }
    } catch (e, st) {
      ref.read(errorHandlerProvider).handle(e, st);
      // Some may have been saved: show what the backend has.
      if (_isShowing(date)) await refreshTasks(date);
    }
  }

  /// Undoes a reorder without touching other changes made meanwhile.
  void _moveBack(String taskId, int index, int priority) {
    final tasks = List<Task>.from(state.value ?? []);
    final current = tasks.indexWhere((t) => t.id == taskId);
    if (current == -1) return;
    final task = tasks.removeAt(current).copyWith(priority: priority);
    tasks.insert(index.clamp(0, tasks.length), task);
    state = AsyncData(tasks);
  }

  void _replaceTask(Task task) => _patchTask(task.id, (_) => task);

  /// Changes a task in the current list: after an await, a list read earlier
  /// may have lost changes made meanwhile.
  void _patchTask(String taskId, Task Function(Task task) change) {
    final tasks = List<Task>.from(state.value ?? []);
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = change(tasks[index]);
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

    // No integer fits between them: spread the priorities out again.
    if (before != null &&
        after != null &&
        after.priority - before.priority < 2) {
      await _renumberPriorities(tasks);
      return;
    }

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

    final selectedDate = ref.read(selectedDateProvider);
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
          date: selectedDate,
        ),
      );
    } catch (e, st) {
      log('Exception: $e stacktrace: $st');
      ref.read(errorHandlerProvider).handle(e, st);
      if (_isShowing(selectedDate)) {
        _moveBack(updatedTask.id, oldIndex, movedTask.priority);
      }
    }
  }
}

class _PendingDelete {
  final Task task;

  /// Position in the list, to restore it in place.
  final int index;
  final DateTime date;
  final Timer timer;
  Future<void>? request;

  _PendingDelete({
    required this.task,
    required this.index,
    required this.date,
    required this.timer,
  });
}

/// Debounce and in-flight state of a task's completion toggle.
class _ToggleSync {
  /// Last state known to be saved on the backend.
  bool confirmed;

  /// Latest state chosen by the user.
  bool wanted;

  Timer? timer;
  bool inFlight = false;
  Future<void> request = Future.value();

  _ToggleSync({required this.confirmed}) : wanted = confirmed;
}

/// Debounce and in-flight state of a task's subtask sync.
class _SubtaskSync {
  /// Last state known to be saved on the backend, for revert on error.
  Task confirmedTask;

  /// Latest completion state chosen by the user, by subtask ID.
  Map<String, bool> subtasks = {};

  Timer? timer;
  bool inFlight = false;
  Future<void> request = Future.value();

  /// Toggles not yet included in a request.
  bool hasUnsentChanges = false;

  _SubtaskSync({required this.confirmedTask});
}

/// The current local day, updated when the app returns to the foreground.
@Riverpod(keepAlive: true)
class Today extends _$Today {
  @override
  DateTime build() {
    final lifecycle = AppLifecycleListener(onResume: refresh);
    ref.onDispose(lifecycle.dispose);
    return _startOfDay(now());
  }

  @visibleForTesting
  DateTime now() => DateTime.now();

  void refresh() => state = _startOfDay(now());

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// The days offered by the date selector. Built from calendar fields because
/// adding 24 hours can land on the same day when daylight saving time changes.
List<DateTime> selectableDays(DateTime today) => [
      for (int i = -3; i < 4; i++)
        DateTime(today.year, today.month, today.day + i),
    ];

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    // Whoever was looking at "today" keeps looking at it after midnight.
    ref.listen(todayProvider, (previous, next) {
      if (state == previous) state = next;
    });
    return ref.read(todayProvider);
  }

  void selectDate(DateTime date) {
    state = date;
  }
}
