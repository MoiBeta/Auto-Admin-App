import 'package:auto_admin_app/core/enums/task_frequency.dart';
import 'package:auto_admin_app/core/models/sub_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskTemplate {
  String id;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<DateTime>? reminders;
  List<Subtask>? subtasks;
  String? imagePath;
  int? customRepeatDays;

  TaskTemplate({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.frequency,
    this.reminders,
    this.subtasks,
    this.imagePath,
    this.customRepeatDays,
  });

  factory TaskTemplate.fromDoc(DocumentSnapshot doc) => TaskTemplate(
      id: doc.id,
      title: doc['title'],
      startDate: (doc['startDate'] as Timestamp).toDate(),
      frequency: TaskFrequency.values.singleWhere((frequency) => frequency.name == doc['frequency']),
  );
}
