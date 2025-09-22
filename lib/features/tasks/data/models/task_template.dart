import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskTemplate {
  String id;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<DateTime>? reminders;
  List<SubTaskModel>? subtasks;
  int? customRepeatDays;
  int priority;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.startDate,
    required this.frequency,
    required this.priority,
    this.description,
    this.reminders,
    this.subtasks,
    this.customRepeatDays,
  });

  factory TaskTemplate.fromDoc(DocumentSnapshot doc) => TaskTemplate(
        id: doc.id,
        title: doc['title'],
        startDate: (doc['startDate'] as Timestamp).toDate(),
        frequency: TaskFrequency.values
            .singleWhere((frequency) => frequency.name == doc['frequency']),
        priority: doc['priority'],
      );
}
