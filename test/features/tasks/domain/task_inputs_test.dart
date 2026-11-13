import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reminder serialization', () {
    test('sends local time and the device UTC offset', () {
      final reminder = DateTime(2026, 10, 27, 20, 15);
      final json = NewTaskData(
        title: 'Leer',
        startDate: DateTime(2026, 10, 27),
        frequency: TaskFrequency.daily,
        priority: 100,
        reminderDate: reminder,
      ).toJson();

      expect(json['reminder']['timeMinutes'], 20 * 60 + 15);
      expect(json['reminder']['utcOffsetMinutes'],
          reminder.timeZoneOffset.inMinutes);
    });
  });

  group('UpdateTaskData.toJson', () {
    UpdateTaskData build({
      List<String>? subTasks,
      String? description,
      DateTime? reminderDate,
      bool removeReminder = false,
      DateTime? newStartDate,
      String? timezone,
    }) =>
        UpdateTaskData(
          taskId: 't1',
          title: 'Leer',
          startDate: DateTime(2026, 10, 27),
          frequency: TaskFrequency.weekly,
          subTasks: subTasks,
          description: description,
          reminderDate: reminderDate,
          removeReminder: removeReminder,
          newStartDate: newStartDate,
          timezone: timezone,
        );

    test('sends an empty list to remove all subtasks', () {
      expect(build(subTasks: []).toJson()['subTasks'], isEmpty);
    });

    test('omits subtasks and description when not provided', () {
      final json = build().toJson() as Map<String, dynamic>;
      expect(json.containsKey('subTasks'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('reminder'), isFalse);
    });

    test('sends the new start day only when it changed', () {
      expect(build().toJson().containsKey('date'), isFalse);
      expect(
        build(newStartDate: DateTime(2026, 11, 2, 18, 45)).toJson()['date'],
        '2026-11-02',
      );
    });

    test('sends the IANA time zone with the reminder', () {
      final json = build(
        reminderDate: DateTime(2026, 10, 27, 7, 30),
        timezone: 'America/Bogota',
      ).toJson();
      expect(json['reminder']['timezone'], 'America/Bogota');
    });

    test('disables the reminder when it is removed', () {
      final json = build(removeReminder: true).toJson();
      expect(json['reminder']['enabled'], isFalse);
    });

    test('a new reminder time takes precedence over removeReminder', () {
      final json = build(
        reminderDate: DateTime(2026, 10, 27, 7, 30),
        removeReminder: true,
      ).toJson();
      expect(json['reminder']['enabled'], isTrue);
      expect(json['reminder']['timeMinutes'], 7 * 60 + 30);
    });
  });

  group('TaskModel reminder', () {
    Map<String, dynamic> json(dynamic reminder) => {
          'id': 'h1',
          'userId': 'u1',
          'title': 'Leer',
          'startDate': '2026-10-27T00:00:00.000Z',
          'completed': false,
          'taskFrequency': 'DAILY',
          'priority': 100,
          'reminder': reminder,
        };

    test('parses the local reminder time', () {
      final task = TaskModel.fromJson(
        json({'timeMinutes': 20 * 60 + 15, 'utcOffsetMinutes': -300}),
      ).toEntity();
      expect(task.reminderDate?.hour, 20);
      expect(task.reminderDate?.minute, 15);
    });

    test('keeps the habit start day as a local calendar day', () {
      final task = TaskModel.fromJson({
        ...json(null),
        'habitStartDate': '2026-10-27T00:00:00.000Z',
      }).toEntity();
      expect(task.habitStartDate, DateTime(2026, 10, 27));
    });

    test('is null when the habit has no active reminder', () {
      expect(TaskModel.fromJson(json(null)).toEntity().reminderDate, isNull);
    });
  });

  test('a one-time task is sent and read as ONCE', () {
    final json = NewTaskData(
      title: 'Renovar pasaporte',
      startDate: DateTime(2026, 11, 12),
      frequency: TaskFrequency.once,
      priority: 100,
    ).toJson();
    expect(json['frequency'], 'ONCE');
    expect(TaskModel.parseFrequency('ONCE'), TaskFrequency.once);
    expect(TaskFrequency.supported, contains(TaskFrequency.once));
  });

  test('only backend-supported frequencies are offered', () {
    expect(TaskFrequency.supported, isNot(contains(TaskFrequency.none)));
    expect(TaskFrequency.supported, isNot(contains(TaskFrequency.custom)));
  });
}
