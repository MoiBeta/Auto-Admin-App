import 'dart:async';

import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/injection/home_injection.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Longer than the toggle and subtask debounce window.
const _debounce = Duration(milliseconds: 1150);

Task _task(
  Map<String, bool> subtasks, {
  String id = 't',
  int priority = 100,
}) =>
    Task(
      id: id,
      userId: 'u',
      title: 't',
      startDate: DateTime(2026, 10, 30),
      completed: false,
      taskFrequency: TaskFrequency.daily,
      priority: priority,
      subtasks: subtasks.entries
          .map((e) => Subtask(id: e.key, title: e.key, completed: e.value))
          .toList(),
    );

Task _completed(String id) => _task({}, id: id).copyWith(completed: true);

class _SyncCall {
  final Map<String, bool> payload;
  final DateTime date;
  final Completer<Task> _response = Completer<Task>();

  _SyncCall(this.payload, this.date);

  void succeed() => _response.complete(_task(payload));
  void fail() => _response.completeError(Exception('sync failed'));
}

class _FakeTasksRepository extends TasksRepository {
  final List<Task> tasks;
  final List<_SyncCall> syncCalls = [];
  final List<UpdateTaskData> edits = [];
  final List<Completer<Task>> toggles = [];
  final List<String> deletes = [];
  Completer<void>? deleteResponse;
  Object? editError;

  /// Overrides the response of getAllTasks, to control when it arrives.
  Future<List<Task>> Function(DateTime date)? onGetAllTasks;

  _FakeTasksRepository(this.tasks);

  @override
  Future<List<Task>> getAllTasks(DateTime date) async =>
      onGetAllTasks?.call(date) ?? tasks;

  @override
  Future<Task> syncSubtasks({
    required String taskId,
    required List<SubtaskState> subtasks,
    required DateTime date,
  }) {
    final call = _SyncCall({
      for (final s in subtasks) s.sourceSubTaskId: s.completed,
    }, date);
    syncCalls.add(call);
    return call._response.future;
  }

  @override
  Future<Task> createNewTask(NewTaskData newTaskData) async =>
      _task({}, id: 'new');
  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) => (
        deletes..add(deleteTaskData.taskId),
        deleteResponse?.future ?? Future.value()
      ).$2;
  @override
  Future<Task> editTask(UpdateTaskData updateTaskData) async {
    edits.add(updateTaskData);
    if (editError != null) throw editError!;
    return _task({}, id: updateTaskData.taskId);
  }

  @override
  Future<Task> toggleTask(ToggleTaskData data) {
    final response = Completer<Task>();
    toggles.add(response);
    return response.future;
  }
}

class _FakeToday extends Today {
  DateTime current;

  _FakeToday(this.current);

  @override
  DateTime now() => current;
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<LoginState> build() async => _session('user-1');

  void signIn(String? userId) => state = AsyncData(_session(userId));

  LoginState _session(String? userId) => LoginState(
        isLoading: false,
        credentials: userId == null
            ? null
            : AuthCredential(
                id: userId,
                fullName: userId,
                email: userId,
                isEmailConfirmed: true,
              ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTasksRepository repository;
  late ProviderContainer container;

  Task currentTask() => container.read(homeProvider).value!.first;

  Map<String, bool> shownSubtasks() => {
        for (final s in currentTask().subtasks!) s.id: s.completed,
      };

  void tap(String subtaskId) {
    container.read(homeProvider.notifier).toggleSubtask(
          task: currentTask(),
          subtask: currentTask().subtasks!.firstWhere((s) => s.id == subtaskId),
          date: container.read(selectedDateProvider),
        );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    repository = _FakeTasksRepository([
      _task({'s1': false, 's2': false}),
    ]);
    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    container.listen(homeProvider, (_, __) {});
    await container.read(authNotifierProvider.future);
    await container.read(homeProvider.future);
  });

  group('toggleSubtask with a sync in flight', () {
    test('a response does not undo a newer toggle, which is sent next',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      expect(repository.syncCalls.single.payload, {'s1': true, 's2': false});

      tap('s2');
      repository.syncCalls.single.succeed();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': true});

      await Future<void>.delayed(_debounce);
      expect(repository.syncCalls, hasLength(2));
      expect(repository.syncCalls.last.payload, {'s1': true, 's2': true});

      repository.syncCalls.last.succeed();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': true});
    });

    test('never sends two requests at once for the same task', () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      tap('s2');
      await Future<void>.delayed(_debounce);
      expect(repository.syncCalls, hasLength(1));

      repository.syncCalls.single.succeed();
      await settle();
      expect(repository.syncCalls, hasLength(2));
      expect(repository.syncCalls.last.payload, {'s1': true, 's2': true});
    });

    test('a failure does not undo a newer toggle, and the retry carries both',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      tap('s2');
      repository.syncCalls.single.fail();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': true});

      await Future<void>.delayed(_debounce);
      expect(repository.syncCalls.last.payload, {'s1': true, 's2': true});

      repository.syncCalls.last.succeed();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': true});
    });
  });

  group('toggleSubtask failure', () {
    test('reverts to the last confirmed state when nothing newer is pending',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      repository.syncCalls.single.fail();
      await settle();
      expect(shownSubtasks(), {'s1': false, 's2': false});
    });

    test('reverts to what the server confirmed, not to the first state',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      tap('s2');
      repository.syncCalls.first.succeed();
      await Future<void>.delayed(_debounce);
      repository.syncCalls.last.fail();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': false});
    });
  });

  group('toggleSubtask when the selected day changes', () {
    late DateTime day1;
    late DateTime day2;

    Future<void> selectDay(DateTime day) async {
      container.read(selectedDateProvider.notifier).selectDate(day);
      await settle();
    }

    setUp(() {
      day1 = container.read(selectedDateProvider);
      day2 = day1.add(const Duration(days: 1));
    });

    test('sends what was toggled, with the day it was toggled on', () async {
      tap('s1');
      await selectDay(day2);
      await Future<void>.delayed(_debounce);

      expect(repository.syncCalls.single.date, day1);
      expect(repository.syncCalls.single.payload, {'s1': true, 's2': false});
    });

    test('a response does not replace the task of the day now shown', () async {
      tap('s1');
      repository.tasks[0] = _task({'s1': false, 's2': true});
      await selectDay(day2);
      await Future<void>.delayed(_debounce);

      repository.syncCalls.single.succeed();
      await settle();
      expect(shownSubtasks(), {'s1': false, 's2': true});
    });

    test('a failure does not replace the task of the day now shown', () async {
      tap('s1');
      repository.tasks[0] = _task({'s1': false, 's2': true});
      await selectDay(day2);
      await Future<void>.delayed(_debounce);

      repository.syncCalls.single.fail();
      await settle();
      expect(shownSubtasks(), {'s1': false, 's2': true});
    });

    test('toggles of the same task on two days are both sent', () async {
      tap('s1');
      await selectDay(day2);
      tap('s2');
      await Future<void>.delayed(_debounce);

      expect(repository.syncCalls, hasLength(2));
      expect(repository.syncCalls.first.date, day1);
      expect(repository.syncCalls.first.payload, {'s1': true, 's2': false});
      expect(repository.syncCalls.last.date, day2);
      expect(repository.syncCalls.last.payload, {'s1': false, 's2': true});
    });

    test('a request in flight for one day does not hold back another day',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      await selectDay(day2);
      tap('s2');
      await Future<void>.delayed(_debounce);

      expect(repository.syncCalls, hasLength(2));
      expect(repository.syncCalls.last.date, day2);
    });

    test('a failure reverts to the confirmed state of its own day', () async {
      tap('s1');
      repository.tasks[0] = _task({'s1': false, 's2': true});
      await selectDay(day2);
      tap('s1');
      await Future<void>.delayed(_debounce);

      repository.syncCalls.first.succeed();
      repository.syncCalls.last.fail();
      await settle();
      expect(shownSubtasks(), {'s1': false, 's2': true});
    });

    test('going back to the day keeps the toggles not yet saved', () async {
      tap('s1');
      await selectDay(day2);
      await selectDay(day1);
      expect(shownSubtasks(), {'s1': true, 's2': false});

      await Future<void>.delayed(_debounce);
      repository.syncCalls.single.succeed();
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': false});
    });
  });

  group('updateTaskPriorities', () {
    List<String> shownOrder() =>
        container.read(homeProvider).value!.map((t) => t.id).toList();

    setUp(() async {
      repository.tasks
        ..clear()
        ..addAll([
          _task({}, id: 'a', priority: 100),
          _task({}, id: 'b', priority: 200),
          _task({}, id: 'c', priority: 300),
        ]);
      await container
          .read(homeProvider.notifier)
          .refreshTasks(container.read(selectedDateProvider));
    });

    // onReorderItem already gives the index after removing the dragged item.
    test('moves a task one position down', () async {
      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 0, newIndex: 1);
      expect(shownOrder(), ['b', 'a', 'c']);
      expect(repository.edits.single.priority, 250);
    });

    test('moves a task to the end', () async {
      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 0, newIndex: 2);
      expect(shownOrder(), ['b', 'c', 'a']);
      expect(repository.edits.single.priority, 400);
    });

    test('renumbers when no integer fits between the neighbours', () async {
      repository.tasks[1] = _task({}, id: 'b', priority: 101);
      await container
          .read(homeProvider.notifier)
          .refreshTasks(container.read(selectedDateProvider));

      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 2, newIndex: 1);

      expect(shownOrder(), ['a', 'c', 'b']);
      expect(
        repository.edits.map((e) => (e.taskId, e.priority)),
        [('c', 200), ('b', 300)],
      );
    });

    test('moves a task up', () async {
      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 2, newIndex: 0);
      expect(shownOrder(), ['c', 'a', 'b']);
      expect(repository.edits.single.priority, 0);
    });
  });

  group('refreshTasks', () {
    test('ignores the response of a day no longer selected', () async {
      final day1 = container.read(selectedDateProvider);
      final day2 = day1.add(const Duration(days: 1));
      final day3 = day1.add(const Duration(days: 2));
      final slow = Completer<List<Task>>();
      repository.onGetAllTasks = (date) => date == day2
          ? slow.future
          : Future.value([
              _task({'s1': true})
            ]);

      container.read(selectedDateProvider.notifier).selectDate(day2);
      await settle();
      container.read(selectedDateProvider.notifier).selectDate(day3);
      await settle();
      slow.complete([
        _task({'s1': false})
      ]);
      await settle();

      expect(shownSubtasks(), {'s1': true});
    });

    test('a load started before a save finished is repeated', () async {
      final day1 = container.read(selectedDateProvider);
      final day2 = day1.add(const Duration(days: 1));
      tap('s1');
      await Future<void>.delayed(_debounce);
      container.read(selectedDateProvider.notifier).selectDate(day2);
      await settle();

      final outdated = Completer<List<Task>>();
      final fresh = Completer<List<Task>>();
      final responses = [outdated, fresh];
      repository.onGetAllTasks = (_) => responses.removeAt(0).future;
      container.read(selectedDateProvider.notifier).selectDate(day1);
      await settle();

      repository.syncCalls.single.succeed();
      await settle();
      expect(responses, isEmpty);

      outdated.complete([
        _task({'s1': false, 's2': false})
      ]);
      fresh.complete([
        _task({'s1': true, 's2': false})
      ]);
      await settle();
      expect(shownSubtasks(), {'s1': true, 's2': false});
    });
  });

  group('pending subtask syncs', () {
    test('flushPendingChanges sends them now and waits for the response',
        () async {
      tap('s1');
      var flushed = false;
      final flush = container
          .read(homeProvider.notifier)
          .flushPendingChanges()
          .then((_) => flushed = true);
      await settle();
      expect(repository.syncCalls, hasLength(1));
      expect(flushed, isFalse);

      repository.syncCalls.single.succeed();
      await flush;
      expect(flushed, isTrue);
    });

    test('flushPendingChanges also waits for changes made during a request',
        () async {
      tap('s1');
      await Future<void>.delayed(_debounce);
      tap('s2');
      final flush = container.read(homeProvider.notifier).flushPendingChanges();
      await settle();

      repository.syncCalls.single.succeed();
      await settle();
      expect(repository.syncCalls.last.payload, {'s1': true, 's2': true});
      repository.syncCalls.last.succeed();
      await flush;
    });

    test('are sent when the app goes to the background', () async {
      tap('s1');
      final binding = TestWidgetsFlutterBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      addTearDown(() =>
          binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      await settle();
      expect(repository.syncCalls.single.payload, {'s1': true, 's2': false});
    });

    test('are sent right away when the selected day changes', () async {
      tap('s1');
      container
          .read(selectedDateProvider.notifier)
          .selectDate(DateTime(2030, 1, 1));
      await settle();
      expect(repository.syncCalls, hasLength(1));
    });

    test('are dropped when the provider is rebuilt', () async {
      tap('s1');
      container.invalidate(homeProvider);
      await container.read(homeProvider.future);
      await Future<void>.delayed(_debounce);
      expect(repository.syncCalls, isEmpty);
    });
  });

  group('session changes', () {
    void signIn(String? userId) =>
        (container.read(authNotifierProvider.notifier) as _FakeAuthNotifier)
            .signIn(userId);

    test('signing out clears the tasks without requesting them', () async {
      var loads = 0;
      repository.onGetAllTasks = (_) async {
        loads++;
        return repository.tasks;
      };
      signIn(null);
      expect(await container.read(homeProvider.future), isEmpty);
      expect(loads, 0);
    });

    test('another user sees their own tasks', () async {
      signIn(null);
      await container.read(homeProvider.future);
      repository.tasks[0] = _task({}, id: 'other-user-task');
      signIn('user-2');
      final tasks = await container.read(homeProvider.future);
      expect(tasks.single.id, 'other-user-task');
    });
  });

  group('changes that overlap', () {
    Task byId(String id) =>
        container.read(homeProvider).value!.firstWhere((t) => t.id == id);

    void toggle(String id) {
      container.read(homeProvider.notifier).toggleTask(
            task: byId(id),
            date: container.read(selectedDateProvider),
          );
    }

    setUp(() async {
      repository.tasks
        ..clear()
        ..addAll([
          _task({}, id: 'a', priority: 100),
          _task({}, id: 'b', priority: 200),
          _task({}, id: 'c', priority: 300),
        ]);
      await container
          .read(homeProvider.notifier)
          .refreshTasks(container.read(selectedDateProvider));
    });

    test('a failed toggle only reverts its own task', () async {
      toggle('a');
      toggle('b');
      await Future<void>.delayed(_debounce);
      repository.toggles.first.completeError(Exception('failed'));
      await settle();

      expect(byId('a').completed, isFalse);
      expect(byId('b').completed, isTrue);
    });

    test('a slow toggle response does not undo a later reorder', () async {
      toggle('a');
      await Future<void>.delayed(_debounce);
      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 2, newIndex: 0);
      repository.toggles.single.complete(_completed('a'));
      await settle();

      expect(
        container.read(homeProvider).value!.map((t) => t.id),
        ['c', 'a', 'b'],
      );
    });

    test('a failed delete does not undo a toggle made meanwhile', () async {
      repository.deleteResponse = Completer<void>();
      final delete = container
          .read(homeProvider.notifier)
          .deleteTask(taskId: 'c', scope: DeleteScope.all);
      toggle('a');
      repository.deleteResponse!.completeError(Exception('failed'));
      await delete;

      expect(byId('a').completed, isTrue);
      expect(byId('c').id, 'c');
    });

    test('a failed reorder restores the order and keeps other changes',
        () async {
      repository.editError = Exception('failed');
      toggle('b');
      await container
          .read(homeProvider.notifier)
          .updateTaskPriorities(oldIndex: 0, newIndex: 2);

      expect(
        container.read(homeProvider).value!.map((t) => t.id),
        ['a', 'b', 'c'],
      );
      expect(byId('a').priority, 100);
      expect(byId('b').completed, isTrue);
    });
  });

  group('toggleTask', () {
    Task byId(String id) =>
        container.read(homeProvider).value!.firstWhere((t) => t.id == id);

    void toggle(String id) {
      container.read(homeProvider.notifier).toggleTask(
            task: byId(id),
            date: container.read(selectedDateProvider),
          );
    }

    setUp(() async {
      repository.tasks
        ..clear()
        ..add(_task({}, id: 'a'));
      await container
          .read(homeProvider.notifier)
          .refreshTasks(container.read(selectedDateProvider));
    });

    test('is shown at once and sent when the taps stop', () async {
      toggle('a');
      expect(byId('a').completed, isTrue);
      expect(repository.toggles, isEmpty);

      await Future<void>.delayed(_debounce);
      expect(repository.toggles, hasLength(1));
    });

    test('tapping twice sends nothing', () async {
      toggle('a');
      toggle('a');
      await Future<void>.delayed(_debounce);

      expect(repository.toggles, isEmpty);
      expect(byId('a').completed, isFalse);
    });

    test('a tap during a request is shown at once and sent after it',
        () async {
      toggle('a');
      await Future<void>.delayed(_debounce);
      toggle('a');
      expect(byId('a').completed, isFalse);

      await Future<void>.delayed(_debounce);
      expect(repository.toggles, hasLength(1));

      repository.toggles.first.complete(_completed('a'));
      await settle();
      expect(repository.toggles, hasLength(2));
      expect(byId('a').completed, isFalse);

      repository.toggles.last.complete(_task({}, id: 'a'));
      await settle();
      expect(repository.toggles, hasLength(2));
      expect(byId('a').completed, isFalse);
    });

    test('taps during a request that cancel out send nothing more', () async {
      toggle('a');
      await Future<void>.delayed(_debounce);
      toggle('a');
      toggle('a');
      await Future<void>.delayed(_debounce);

      repository.toggles.single.complete(_completed('a'));
      await settle();
      expect(repository.toggles, hasLength(1));
      expect(byId('a').completed, isTrue);
    });

    test('a failed request shows the saved state and drops later taps',
        () async {
      toggle('a');
      await Future<void>.delayed(_debounce);
      toggle('a');
      toggle('a');

      repository.toggles.single.completeError(Exception('failed'));
      await settle();
      expect(byId('a').completed, isFalse);

      await Future<void>.delayed(_debounce);
      expect(repository.toggles, hasLength(1));
    });

    test('flushPendingChanges sends it right away', () async {
      toggle('a');
      final flush = container.read(homeProvider.notifier).flushPendingChanges();
      await settle();
      expect(repository.toggles, hasLength(1));

      repository.toggles.single.complete(_completed('a'));
      await flush;
      expect(byId('a').completed, isTrue);
    });

    test('a reload keeps a toggle not yet saved', () async {
      toggle('a');
      await container
          .read(homeProvider.notifier)
          .refreshTasks(container.read(selectedDateProvider));

      expect(byId('a').completed, isTrue);
    });

    group('of a one-time task', () {
      Task once({required bool completed}) => _task({}, id: 'a')
          .copyWith(taskFrequency: TaskFrequency.once, completed: completed);

      Future<void> show(DateTime day) async {
        repository.tasks
          ..clear()
          ..add(once(completed: true));
        container.read(selectedDateProvider.notifier).selectDate(day);
        await settle();
      }

      test('undone on a past day, it leaves that day', () async {
        final today = container.read(todayProvider);
        await show(DateTime(today.year, today.month, today.day - 1));
        expect(byId('a').completed, isTrue);

        toggle('a');
        await Future<void>.delayed(_debounce);
        // Pending again, so the backend only returns it for today.
        repository.tasks.clear();
        repository.toggles.single.complete(once(completed: false));
        await settle();

        expect(container.read(homeProvider).value, isEmpty);
      });

      test('undone today, it stays on the list', () async {
        await show(container.read(todayProvider));
        var loads = 0;
        repository.onGetAllTasks = (_) async {
          loads++;
          return repository.tasks;
        };

        toggle('a');
        await Future<void>.delayed(_debounce);
        repository.toggles.single.complete(once(completed: false));
        await settle();

        expect(loads, 0);
        expect(byId('a').completed, isFalse);
      });
    });
  });

  group('days', () {
    test('selectableDays gives seven consecutive days at midnight', () {
      final days = selectableDays(DateTime(2026, 3, 8));
      expect(days.first, DateTime(2026, 3, 5));
      expect(days.last, DateTime(2026, 3, 11));
      expect(days.map((d) => d.day).toSet(), hasLength(7));
      expect(days.every((d) => d.hour == 0), isTrue);
    });

    test('the selection follows today after midnight unless it was moved', () {
      final clock = _FakeToday(DateTime(2026, 10, 30, 23));
      final dates = ProviderContainer(
        overrides: [todayProvider.overrideWith(() => clock)],
      );
      addTearDown(dates.dispose);
      dates.listen(selectedDateProvider, (_, __) {});

      clock.current = DateTime(2026, 10, 31, 0, 5);
      dates.read(todayProvider.notifier).refresh();
      expect(dates.read(selectedDateProvider), DateTime(2026, 10, 31));

      dates
          .read(selectedDateProvider.notifier)
          .selectDate(DateTime(2026, 10, 29));
      clock.current = DateTime(2026, 11, 1);
      dates.read(todayProvider.notifier).refresh();
      expect(dates.read(selectedDateProvider), DateTime(2026, 10, 29));
    });
  });

  group('createTask', () {
    Future<Task?> create() => container.read(homeProvider.notifier).createTask(
          title: 'new',
          startDate: DateTime(2026, 12, 1),
          frequency: TaskFrequency.weekly,
        );

    test('does not list a task the backend does not schedule that day',
        () async {
      final created = await create();
      expect(created?.id, 'new');
      expect(currentTask().id, 't');
      expect(container.read(homeProvider).value, hasLength(1));
    });

    test('lists a task the backend schedules that day', () async {
      repository.tasks.add(_task({}, id: 'new'));
      await create();
      expect(container.read(homeProvider).value, hasLength(2));
    });
  });

  test('a load in progress when the session ends does not show its tasks',
      () async {
    final slow = Completer<List<Task>>();
    repository.onGetAllTasks = (_) => slow.future;
    final notifier = container.read(homeProvider.notifier);
    final load = notifier.refreshTasks(container.read(selectedDateProvider));

    (container.read(authNotifierProvider.notifier) as _FakeAuthNotifier)
        .signIn(null);
    expect(await container.read(homeProvider.future), isEmpty);

    slow.complete([_task({}, id: 'previous-user-task')]);
    await load;
    expect(container.read(homeProvider).value, isEmpty);
  });

  group('scheduleDelete', () {
    HomeNotifier notifier() => container.read(homeProvider.notifier);

    setUp(() async {
      repository.tasks
        ..clear()
        ..addAll([
          _task({}, id: 'a', priority: 100),
          _task({}, id: 'b', priority: 200),
        ]);
      await notifier().refreshTasks(container.read(selectedDateProvider));
    });

    List<String> shownIds() =>
        container.read(homeProvider).value!.map((t) => t.id).toList();

    test('undo restores the task in place without deleting it', () async {
      notifier().scheduleDelete(currentTask());
      expect(shownIds(), ['b']);

      notifier().undoDelete('a');
      await notifier().flushPendingChanges();
      expect(shownIds(), ['a', 'b']);
      expect(repository.deletes, isEmpty);
    });

    test('stays hidden if the list reloads during the undo window', () async {
      notifier().scheduleDelete(currentTask());
      await notifier().refreshTasks(container.read(selectedDateProvider));
      expect(shownIds(), ['b']);
    });

    test('is sent once when the pending changes are flushed', () async {
      notifier().scheduleDelete(currentTask());
      await Future.wait([
        notifier().flushPendingChanges(),
        notifier().flushPendingChanges(),
      ]);
      expect(repository.deletes, ['a']);
      expect(shownIds(), ['b']);
    });

    test('shows the task again if the backend could not delete it', () async {
      repository.deleteResponse = Completer<void>()
        ..completeError(Exception('failed'));
      notifier().scheduleDelete(currentTask());
      await notifier().flushPendingChanges();
      expect(shownIds(), ['a', 'b']);
    });
  });
}
