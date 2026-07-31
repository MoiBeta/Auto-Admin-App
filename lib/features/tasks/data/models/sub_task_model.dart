import 'package:auto_admin_app/features/tasks/data/models/sub_task_instance.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_template.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';

class SubTaskModel {
  String id;
  String title;
  bool completed;

  SubTaskModel({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory SubTaskModel.fromJson(dynamic json) {
    return SubTaskModel(
      id: (json['sourceSubTaskId'] ?? '') as String,
      title: json['title'] as String,
      completed: (json['completed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      //  'sourceSubTaskId': id,
      'title': title,
      // 'completed': completed,
    };
  }

  Subtask toEntity() {
    return Subtask(
      id: id,
      title: title,
      completed: completed,
    );
  }

  factory SubTaskModel.fromTemplateAndInstance(
      SubTaskTemplate template, SubTaskInstance instance) {
    return SubTaskModel(
      id: instance.id,
      title: template.title,
      completed: instance.completed,
    );
  }
}
