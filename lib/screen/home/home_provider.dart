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

  StreamSubscription? _subscription;

  @override
  List<TaskInstance> build() {
    _listenToTasks(ref.watch(selectedDateProvider));

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  void _listenToTasks(DateTime selectedDate) {

    if(_subscription == null){
      FirebaseFirestore.instance
          .collection('taskInstances')
          .where(
        'date',
        isEqualTo: Timestamp.fromDate(selectedDate),
      )
          .get()
          .then((QuerySnapshot snapshot) {
        if (snapshot.docs.isNotEmpty) {
          state = snapshot.docs.map((doc) => TaskInstance.fromDoc(doc)).toList();
        }
      });
    }

    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('taskInstances')
        .where(
          'date',
          isEqualTo: Timestamp.fromDate(selectedDate),
        )
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docs.isNotEmpty) {
        state = snapshot.docs.map((doc) => TaskInstance.fromDoc(doc)).toList();
      }
    });
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
    await FirebaseFirestore.instance
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

    // 1️⃣ Obtener y eliminar todas las instancias de la tarea
    final taskInstances = await firestore
        .collection("taskInstances")
        .where("taskTemplateId", isEqualTo: taskTemplateId)
        .get();

    for (var doc in taskInstances.docs) {
      batch.delete(doc.reference);
    }

    // 2️⃣ Eliminar la plantilla de la tarea
    final taskTemplateRef = firestore.collection("taskTemplates").doc(taskTemplateId);
    batch.delete(taskTemplateRef);

    // 3️⃣ Aplicar los cambios
    await batch.commit();
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
