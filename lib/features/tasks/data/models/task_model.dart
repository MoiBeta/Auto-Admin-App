import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';

class TaskModel {
  String id;
  String userId;
  String title;
  String? description;
  DateTime startDate;
  List<SubTaskModel>? subtasks;
  bool completed;
  TaskFrequency taskFrequency;
  int priority;

  /// Reminder time (only hour and minute are meaningful), null if none.
  DateTime? reminderDate;

  /// Local day the habit starts.
  DateTime? habitStartDate;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.completed,
    required this.taskFrequency,
    required this.priority,
    this.description,
    this.subtasks,
    this.reminderDate,
    this.habitStartDate,
  });

  Task toEntity() => Task(
        id: id,
        userId: userId,
        title: title,
        description: description,
        startDate: startDate,
        subtasks: subtasks?.map((model) => model.toEntity()).toList(),
        completed: completed,
        taskFrequency: taskFrequency,
        priority: priority,
        reminderDate: reminderDate,
        habitStartDate: habitStartDate,
      );

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        userId: json['userId'],
        title: json['title'],
        description: json['description'],
        startDate: DateTime.parse(json['startDate']),
        subtasks: (json['subtasks'] as List<dynamic>?)
            ?.map((e) => SubTaskModel.fromJson(e))
            .toList(),
        completed: json['completed'],
        taskFrequency: parseFrequency(json['taskFrequency']),
        priority: parsePriority(json['priority']),
        reminderDate: parseReminder(json['reminder']),
        habitStartDate: parseDay(json['habitStartDate']),
      );

  /// The backend stores days as UTC midnight; keep the calendar day as a
  /// local date instead of converting the instant to local time.
  static DateTime? parseDay(dynamic value) {
    if (value is! String) return null;
    final utc = DateTime.tryParse(value)?.toUtc();
    return utc == null ? null : DateTime(utc.year, utc.month, utc.day);
  }

  /// The backend stores the reminder as local minutes since midnight.
  static DateTime? parseReminder(dynamic reminder) {
    if (reminder is! Map || reminder['timeMinutes'] is! int) return null;
    final minutes = reminder['timeMinutes'] as int;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
  }

  static TaskFrequency parseFrequency(dynamic frequency) {
    if (frequency is String) {
      return TaskFrequency.values.firstWhere(
        (e) => e.name.toLowerCase() == frequency.toLowerCase(),
        orElse: () => TaskFrequency.none,
      );
    }
    return TaskFrequency.none;
  }

  static int parsePriority(dynamic priority) {
    if (priority is int) return priority;
    if (priority is String) return int.tryParse(priority) ?? 0;
    return 0;
  }
}
