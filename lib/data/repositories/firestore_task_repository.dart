import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/data/models/sub_task.dart';
import 'package:auto_admin_app/data/models/task_instance.dart';
import 'package:auto_admin_app/data/models/task_template.dart';
import 'package:auto_admin_app/data/repositories/task_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Future<void> createRecurringTaskInstances({
    required String userId,
    required String taskTemplateId,
    required DateTime startDate,
    required TaskFrequency frequency,
    int daysAhead = 30,
  }) async {
    List<Map<String, dynamic>> taskInstances = [];
    DateTime currentDate = startDate;
    for (int i = 0; i < daysAhead; i++) {
      taskInstances.add({
        'userId': userId,
        'taskTemplateId': taskTemplateId,
        'date': Timestamp.fromDate(currentDate),
        'completed': false,
        'completedAt': null,
      });

      switch (frequency) {
        case TaskFrequency.daily:
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case TaskFrequency.weekly:
          currentDate = currentDate.add(Duration(days: 7));
          break;
        case TaskFrequency.monthly:
          currentDate = DateTime(
              currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case TaskFrequency.yearly:
          currentDate = DateTime(
              currentDate.year + 1, currentDate.month, currentDate.day);
          break;
        case TaskFrequency.none:
          break;
        case TaskFrequency.custom:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }

    WriteBatch batch = firestore.batch();
    for (var task in taskInstances) {
      var docRef = firestore.collection('taskInstances').doc();
      batch.set(docRef, task);
    }
    await batch.commit();
  }

  @override
  Future<String> createTaskTemplate({
    required String userId,
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<Subtask> subtasks = const [],
    int priority = 0,
  }) async {
    final taskTemplateRef = firestore.collection('taskTemplates').doc();
    await taskTemplateRef.set({
      'userId': userId,
      'title': title,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'subtasks': subtasks
          .map((s) => {'id': s.id, 'title': s.title, 'completed': false})
          .toList(),
      'priority': priority,
    });
    return taskTemplateRef.id;
  }

  @override
  Future<List<TaskTemplate>> fetchTaskTemplates({
    required String userId,
  }) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('taskTemplates')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .orderBy('priority')
        .get();

    return snapshot.docs.map((doc) => TaskTemplate.fromDoc(doc)).toList();
  }

  @override
  Future<List<TaskInstance>> getTaskInstances({
    required DateTime selectedDate,
    required String userId,
  }) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('taskInstances')
        .where(
          'date',
          isEqualTo: Timestamp.fromDate(selectedDate),
        )
        .where(
          'userId',
          isEqualTo: userId,
        )
        .get();

    if (snapshot.docs.isNotEmpty) {
      return sortTaskInstances(
        snapshot.docs
            .map(
              (doc) => TaskInstance.fromDoc(doc),
            )
            .toList(),
        userId,
      );
    }
    return [];
  }

  Future<List<TaskInstance>> sortTaskInstances(
    List<TaskInstance> taskInstances,
    String userId,
  ) async {
    List<TaskTemplate> taskTemplates = await fetchTaskTemplates(userId: '');
    Map<String, int> templatePriorityMap = {
      for (var template in taskTemplates) template.id: template.priority
    };

    taskInstances.sort((a, b) {
      int priorityA = templatePriorityMap[a.taskTemplateId] ?? 0;
      int priorityB = templatePriorityMap[b.taskTemplateId] ?? 0;
      return priorityA.compareTo(priorityB);
    });

    return taskInstances;
  }
}
