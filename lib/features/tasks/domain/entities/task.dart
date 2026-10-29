import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';

class Task {
  String id;
  String userId;
  String title;
  String? description;
  DateTime startDate;
  List<Subtask>? subtasks;
  bool completed;
  DateTime? completedAt;
  TaskFrequency taskFrequency;
  DateTime? reminderDate;
  int priority;

  /// Local day the habit starts; weekly/monthly/yearly habits repeat on it.
  /// [startDate] is the day of the period being shown.
  DateTime? habitStartDate;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.completed,
    required this.taskFrequency,
    required this.priority,
    this.completedAt,
    this.description,
    this.subtasks = const [],
    this.reminderDate,
    this.habitStartDate,
  });

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startDate,
    List<Subtask>? subtasks,
    bool? completed,
    DateTime? completedAt,
    TaskFrequency? taskFrequency,
    DateTime? reminderDate,
    int? priority,
    DateTime? habitStartDate,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      subtasks: subtasks ?? this.subtasks,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      taskFrequency: taskFrequency ?? this.taskFrequency,
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
      habitStartDate: habitStartDate ?? this.habitStartDate,
    );
  }
}
