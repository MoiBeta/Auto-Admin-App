import 'package:auto_admin_app/features/tasks/data/models/sub_task.dart';

class Task {
  String id;
  String userId;
  String title;
  String? description;
  DateTime startDate;
  List<Subtask>? subtasks;
  bool completed;
  DateTime? completedAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.completed,
    this.completedAt,
    this.description,
    this.subtasks,
  });

}
