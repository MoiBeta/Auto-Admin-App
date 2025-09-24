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
  final String templateId;
  final String instanceId;
  TaskFrequency taskFrequency;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.completed,
    required this.templateId,
    required this.instanceId,
    required this.taskFrequency,
    this.completedAt,
    this.description,
    this.subtasks = const [],
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
    String? templateId,
    String? instanceId,
    TaskFrequency? taskFrequency,
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
      templateId: templateId ?? this.templateId,
      instanceId: instanceId ?? this.instanceId,
      taskFrequency: taskFrequency ?? this.taskFrequency,
    );
  }
}
