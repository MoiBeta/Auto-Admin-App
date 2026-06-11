import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_model.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_instance.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_template.dart';
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
      );

  factory TaskModel.fromTemplateAndInstance(
      TaskTemplate template, TaskInstance instance) {
    return TaskModel(
      id: instance.id,
      userId: instance.userId,
      title: template.title,
      description: template.description,
      subtasks: instance.subtasks,
      startDate: instance.date,
      completed: instance.completed,
      taskFrequency: template.frequency,
      priority: template.priority,
    );
  }

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
      );

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
