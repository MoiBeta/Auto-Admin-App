import 'package:auto_admin_app/data/enums/task_frequency.dart';

class TaskData {
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<String>? subTasks;

  TaskData({
    required this.title,
    required this.startDate,
    required this.frequency,
    this.description,
    this.subTasks,
  });
}
