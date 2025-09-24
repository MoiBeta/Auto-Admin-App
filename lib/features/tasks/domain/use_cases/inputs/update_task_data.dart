import 'package:auto_admin_app/data/enums/task_frequency.dart';

class UpdateTaskTemplateData {
  String templateId;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<String>? subTasks;
  int? priority;

  UpdateTaskTemplateData({
    required this.templateId,
    required this.title,
    required this.startDate,
    required this.frequency,
    this.priority,
    this.description,
    this.subTasks,
  });
}
