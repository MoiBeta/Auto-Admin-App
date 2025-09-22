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

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }

  Subtask toEntity() {
    return Subtask(
      id: id,
      title: title,
      completed: completed,
    );
  }

  factory SubTaskModel.fromEntity(Subtask entity) {
    return SubTaskModel(
      id: entity.id,
      title: entity.title,
      completed: entity.completed,
    );
  }
}
