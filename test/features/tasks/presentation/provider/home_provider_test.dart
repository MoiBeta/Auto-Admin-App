import 'dart:async';

import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/injection/home_injection.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Longer than the subtask debounce window.
const _debounce = Duration(milliseconds: 1150);

Task _task(Map<String, bool> subtasks) => Task(
      id: 't',
      userId: 'u',
      title: 't',
      startDate: DateTime(2026, 10, 30),
      completed: false,
      taskFrequency: TaskFrequency.daily,
      priority: 100,
      subtasks: subtasks.entries
          .map((e) => Subtask(id: e.key, title: e.key, completed: e.value))
          .toList(),
    );

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

  _FakeTasksRepository(this.tasks);

  @override
  Future<List<Task>> getAllTasks(DateTime date) async => tasks;

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
  Future<Task> createNewTask(NewTaskData newTaskData) =>
      throw UnimplementedError();
  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) =>
      throw UnimplementedError();
  @override
  Future<Task> editTask(UpdateTaskData updateTaskData) =>
      throw UnimplementedError();
  @override
  Future<Task> toggleTask(ToggleTaskData data) => throw UnimplementedError();
}

void main() {
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
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(homeProvider, (_, __) {});
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
}
