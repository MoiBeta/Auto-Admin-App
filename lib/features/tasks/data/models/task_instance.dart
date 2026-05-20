import 'package:auto_admin_app/features/tasks/data/models/sub_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskInstance {
  String id;
  String userId;
  String taskTemplateId;
  DateTime date;
  bool completed;
  DateTime? completedAt;
  List<SubTaskModel>? subtasks;

  TaskInstance({
    required this.id,
    required this.userId,
    required this.taskTemplateId,
    required this.date,
    required this.completed,
    this.subtasks = const [],
    this.completedAt,
  });

  factory TaskInstance.fromDoc(DocumentSnapshot doc) {
    List<SubTaskModel> subTasks = [];
    try {
      subTasks = (doc['subtasks'] as List<dynamic>)
          .map((json) => SubTaskModel.fromJson(json))
          .toList();
    } catch (_) {}

    return TaskInstance(
      id: doc.id,
      userId: doc['userId'],
      taskTemplateId: doc['taskTemplateId'],
      date: (doc['date'] as Timestamp).toDate(),
      completed: doc['completed'],
      subtasks: subTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taskTemplateId': taskTemplateId,
      'date': date,
      'subtasks': subtasks?.map((subTask) => subTask.toJson()).toList(),
      'completed': completed,
    };
  }
}
