import 'dart:async';

import 'package:auto_admin_app/core/enums/task_frequency.dart';
import 'package:auto_admin_app/core/models/sub_task.dart';
import 'package:auto_admin_app/core/models/task_instance.dart';
import 'package:auto_admin_app/core/models/task_template.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'home_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeNotifier extends _$HomeNotifier {
  List<TaskTemplate> taskTemplates = [];

  @override
  List<TaskInstance> build() {
    getTaskInstances(ref.watch(selectedDateProvider));
    return [];
  }

  Future<void> getTaskInstances(DateTime selectedDate) async {
    List<TaskInstance> taskInstances = [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('taskInstances')
        .where(
          'date',
          isEqualTo: Timestamp.fromDate(selectedDate),
        )
        .get();

    if (snapshot.docs.isNotEmpty) {
      taskInstances = await sortTaskInstances(
        snapshot.docs
            .map(
              (doc) => TaskInstance.fromDoc(doc),
            )
            .toList(),
      );
    }

    state = taskInstances;
  }

  Future<List<TaskInstance>> sortTaskInstances(
      List<TaskInstance> taskInstances) async {
    taskTemplates = await fetchTaskTemplates();
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

  Future<void> createRecurringTask({
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<Subtask> subtasks = const [],
    int daysAhead = 30,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final taskTemplateRef = firestore.collection('taskTemplates').doc();
    await taskTemplateRef.set({
      'title': title,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'subtasks': subtasks
          .map((s) => {'id': s.id, 'title': s.title, 'completed': false})
          .toList(),
    });

    List<Map<String, dynamic>> taskInstances = [];
    DateTime currentDate = startDate;
    for (int i = 0; i < daysAhead; i++) {
      taskInstances.add({
        'taskTemplateId': taskTemplateRef.id,
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

  Future<void> completeTask(
      {required String taskInstanceId, required bool completed}) async {

    List<TaskInstance> instances = List<TaskInstance>.from(state);

    int index = instances.indexWhere((instance) => instance.id == taskInstanceId);
    instances[index].completed = completed;

    state = instances;

    FirebaseFirestore.instance
        .collection('taskInstances')
        .doc(taskInstanceId)
        .update({
      'completed': completed,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<TaskTemplate?> getTaskTemplateFromId(String taskTemplateId) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('taskTemplates')
        .doc(taskTemplateId)
        .get();

    if (doc.exists) {
      return TaskTemplate.fromDoc(doc);
    }
    return null;
  }

  Future<void> deleteRecurringTask(String taskTemplateId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();

    final taskInstances = await firestore
        .collection("taskInstances")
        .where("taskTemplateId", isEqualTo: taskTemplateId)
        .get();

    for (var doc in taskInstances.docs) {
      batch.delete(doc.reference);
    }

    final taskTemplateRef =
        firestore.collection("taskTemplates").doc(taskTemplateId);
    batch.delete(taskTemplateRef);

    await batch.commit();
  }

  Future<void> updateTaskPriorities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    List<TaskInstance> instances = List.from(state);

    final taskItem = instances.removeAt(oldIndex);
    instances.insert(newIndex, taskItem);

    state = instances;

    updateTasksInDatabase(oldIndex, newIndex);
  }

  Future<void> updateTasksInDatabase(int oldIndex, int newIndex) async {
    final templateItem = taskTemplates.removeAt(oldIndex);
    taskTemplates.insert(newIndex, templateItem);

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < taskTemplates.length; i++) {
      final task = taskTemplates[i];
      final docRef =
          FirebaseFirestore.instance.collection('taskTemplates').doc(task.id);

      batch.update(docRef, {'priority': i + 1});
    }

    await batch.commit();
  }

  Future<List<TaskTemplate>> fetchTaskTemplates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('taskTemplates')
        .orderBy('priority')
        .get();

    return snapshot.docs.map((doc) => TaskTemplate.fromDoc(doc)).toList();
  }
}

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    return DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  void selectDate(DateTime date) {
    state = date;
  }
}
