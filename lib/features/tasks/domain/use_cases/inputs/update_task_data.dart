import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';

class UpdateTaskData {
  String taskId;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<String>? subTasks;
  int? priority;

  UpdateTaskData({
    required this.taskId,
    required this.title,
    required this.startDate,
    required this.frequency,
    this.priority,
    this.description,
    this.subTasks,
  });
}
