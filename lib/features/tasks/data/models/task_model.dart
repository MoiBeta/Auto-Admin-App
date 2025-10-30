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
  DateTime? completedAt;
  final String templateId;
  final String instanceId;
  TaskFrequency taskFrequency;

  TaskModel({
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
        completedAt: completedAt,
        templateId: templateId,
        instanceId: instanceId,
        taskFrequency: taskFrequency,
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
      completedAt: instance.completedAt,
      templateId: template.id,
      instanceId: instance.id,
      taskFrequency: template.frequency,
    );
  }
}
