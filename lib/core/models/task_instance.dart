import 'package:cloud_firestore/cloud_firestore.dart';

class TaskInstance {
  String id;
  String taskTemplateId;
  DateTime date;
  bool completed;
  DateTime? completedAt;

  TaskInstance({
    required this.id,
    required this.taskTemplateId,
    required this.date,
    required this.completed,
    this.completedAt,
  });

  factory TaskInstance.fromDoc(DocumentSnapshot doc) => TaskInstance(
    id: doc.id,
    taskTemplateId: doc['taskTemplateId'],
    date: (doc['date'] as Timestamp).toDate(),
    completed: doc['completed'],
  );
}
