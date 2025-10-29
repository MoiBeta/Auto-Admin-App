import 'dart:async';
import 'dart:developer';

import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_model.dart';
import 'package:auto_admin_app/features/tasks/data/models/sub_task_template.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_instance.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_template.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDataSource extends TasksDataSource {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  CollectionReference get _taskTemplatesCollection =>
      firestore.collection("taskTemplates");

  CollectionReference get _taskInstancesCollection =>
      firestore.collection("taskInstances");

  String get userId => firebaseAuth.currentUser!.uid;

  @override
  Future<TaskModel> createNewTask(TaskData newTaskData) async {
    TaskTemplate taskTemplate = await createTaskTemplate(
      userId: userId,
      title: newTaskData.title,
      frequency: newTaskData.frequency,
      startDate: newTaskData.startDate,
      description: newTaskData.description,
      subtasks: newTaskData.subTasks != null
          ? newTaskData.subTasks!
              .asMap()
              .entries
              .map(
                (entry) => SubTaskTemplate(
                  id: entry.key.toString(),
                  title: entry.value,
                ),
              )
              .toList()
          : [],
      priority: newTaskData.priority,
      reminders: [],
    );
    List<TaskInstance> taskInstances = await createRecurringTaskInstances(
      userId: userId,
      taskTemplateId: taskTemplate.id,
      startDate: newTaskData.startDate,
      frequency: newTaskData.frequency,
    );

    return TaskModel.fromTemplateAndInstance(
      taskTemplate,
      taskInstances.firstWhere(
        (instance) => instance.date == newTaskData.startDate,
      ),
    );
  }

  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) async {
    final batch = firestore.batch();

    switch (deleteTaskData.scope) {
      case DeleteScope.onlyOne:
        _taskInstancesCollection.doc(deleteTaskData.instanceId).delete();
        break;

      case DeleteScope.future:
        if (deleteTaskData.referenceDate == null) {
          throw ArgumentError(
              "referenceDate is required for DeleteScope.future");
        }
        final futureInstances = await _taskInstancesCollection
            .where("taskTemplateId", isEqualTo: deleteTaskData.templateId)
            .where("date",
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(deleteTaskData.referenceDate!))
            .get();

        for (var doc in futureInstances.docs) {
          batch.delete(doc.reference);
        }
        break;

      case DeleteScope.all:
        final allInstances = await _taskInstancesCollection
            .where("taskTemplateId", isEqualTo: deleteTaskData.templateId)
            .get();

        for (var doc in allInstances.docs) {
          batch.delete(doc.reference);
        }

        final taskTemplateRef =
            _taskTemplatesCollection.doc(deleteTaskData.templateId);
        batch.delete(taskTemplateRef);
        break;
    }

    await batch.commit();
  }

  @override
  Future<TaskModel> editTaskTemplate(
      UpdateTaskTemplateData updateTaskData) async {
    TaskTemplate taskTemplate = await updateTaskTemplate(
      taskTemplateId: updateTaskData.templateId,
      userId: userId,
      title: updateTaskData.title,
      frequency: updateTaskData.frequency,
      startDate: updateTaskData.startDate,
      subtasks: (updateTaskData.subTasks ?? [])
          .asMap()
          .entries
          .map(
            (entry) => SubTaskTemplate(
              id: entry.key.toString(),
              title: entry.value,
            ),
          )
          .toList(),
      priority: updateTaskData.priority,
    );

    List<TaskInstance> taskInstances = await updateRecurringTaskInstances(
      userId: userId,
      taskTemplateId: updateTaskData.templateId,
      startDate: updateTaskData.startDate,
      frequency: updateTaskData.frequency,
    );

    return TaskModel.fromTemplateAndInstance(
      taskTemplate,
      taskInstances.firstWhere(
        (instance) => instance.date == updateTaskData.startDate,
      ),
    );
  }

  @override
  Future<TaskModel> editTaskInstance(UpdateTaskInstanceData newTaskData) async {
    await firestore
        .collection("taskInstances")
        .doc(newTaskData.instanceId)
        .update({
      'completed': newTaskData.completed,
      'completedAt': newTaskData.completedAt,
      'subtasks': newTaskData.subtaskStates
    });
    DocumentSnapshot doc = await firestore
        .collection("taskInstances")
        .doc(newTaskData.instanceId)
        .get();

    TaskInstance instance = TaskInstance.fromDoc(doc);

    TaskTemplate template = await getTaskTemplateById(
      taskTemplateId: instance.taskTemplateId,
    );

    return TaskModel.fromTemplateAndInstance(
      template,
      instance,
    );
  }

  @override
  Future<List<TaskModel>> getAllTasks(DateTime date) async {
    final List<TaskTemplate> templates = await fetchTaskTemplates(
      userId: userId,
    );

    final allInstances = <TaskInstance>[];
    for (var template in templates) {
      final instances = await getTaskInstances(
        selectedDate: date,
        userId: firebaseAuth.currentUser!.uid,
        taskTemplateId: template.id,
      );
      allInstances.addAll(instances);
    }

    return allInstances.map((i) {
      final template = templates.firstWhere((t) => t.id == i.taskTemplateId);
      return TaskModel.fromTemplateAndInstance(template, i);
    }).toList();
  }

  @override
  Future<void> checkAndCreateUpcomingInstances() async {
    final List<TaskTemplate> templates = await fetchTaskTemplates(
      userId: userId,
    );
    try {
      for (final template in templates) {
        await ensureUpcomingTaskInstancesUpToDate(
          taskTemplateId: template.id,
          startDate: template.startDate,
          frequency: template.frequency,
        );
      }
    } catch (e) {
      // Puedes ignorar o loguear el error
      log('Error creating missing instances: $e');
    }
  }

  Future<void> ensureUpcomingTaskInstancesUpToDate({
    required String taskTemplateId,
    required DateTime startDate,
    required TaskFrequency frequency,
  }) async {
    final collection = firestore.collection('taskInstances');
    final today = DateTime.now();

    final existingDocs = await collection
        .where('taskTemplateId', isEqualTo: taskTemplateId)
        .where('date', isGreaterThanOrEqualTo: today)
        .orderBy('date')
        .get();

    final existingDates = existingDocs.docs
        .map((doc) => (doc['date'] as Timestamp).toDate())
        .toList();

    DateTime nextDate =
        existingDates.isNotEmpty ? existingDates.last : startDate;

    final DateTime limitDate = today.add(const Duration(days: 30));
    final List<TaskInstance> newInstances = [];

    while (nextDate.isBefore(limitDate)) {
      final exists = existingDates.any((d) =>
          d.year == nextDate.year &&
          d.month == nextDate.month &&
          d.day == nextDate.day);

      if (!exists) {
        newInstances.add(TaskInstance(
          id: '${taskTemplateId}_${nextDate.toIso8601String()}',
          userId: userId,
          taskTemplateId: taskTemplateId,
          date: nextDate,
          completed: false,
          completedAt: null,
        ));
      }

      nextDate = _getNextDate(nextDate, frequency);
    }

    // 🔹 Crear solo las que faltan
    if (newInstances.isNotEmpty) {
      final batch = firestore.batch();
      for (final task in newInstances) {
        final docRef = collection.doc(task.id);
        batch.set(docRef, task.toJson());
      }
      await batch.commit();
    }
  }

  /// Auxiliar para avanzar a la siguiente fecha según frecuencia
  DateTime _getNextDate(DateTime current, TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return current.add(const Duration(days: 1));
      case TaskFrequency.weekly:
        return current.add(const Duration(days: 7));
      case TaskFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case TaskFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
      case TaskFrequency.none:
        return current;
      case TaskFrequency.custom:
        throw UnimplementedError('Custom frequency not implemented');
    }
  }

  Future<List<TaskInstance>> createRecurringTaskInstances({
    required String userId,
    required String taskTemplateId,
    required DateTime startDate,
    required TaskFrequency frequency,
    List<SubTaskTemplate> subTasksTemplates = const [],
  }) async {
    final List<TaskInstance> createdInstances = [];
    DateTime currentDate = startDate;

    WriteBatch batch = firestore.batch();

    final daysAhead = frequency == TaskFrequency.daily
        ? 30
        : frequency == TaskFrequency.weekly
            ? 8
            : frequency == TaskFrequency.monthly
                ? 4
                : frequency == TaskFrequency.yearly
                    ? 2
                    : 1;

    for (int i = 0; i < daysAhead; i++) {
      final docRef = firestore.collection('taskInstances').doc();

      final data = {
        'userId': userId,
        'taskTemplateId': taskTemplateId,
        'date': Timestamp.fromDate(currentDate),
        'completed': false,
        'completedAt': null,
        if (subTasksTemplates.isNotEmpty)
          'subtasks': subTasksTemplates
              .map((s) => {
                    'id': s.id,
                    'title': s.title,
                    'completed': false,
                  })
              .toList(),
      };

      batch.set(docRef, data);

      createdInstances.add(TaskInstance(
        id: docRef.id,
        userId: userId,
        taskTemplateId: taskTemplateId,
        date: currentDate,
        completed: false,
        completedAt: null,
        subtasks: subTasksTemplates
            .map((s) => SubTaskModel(
                  id: s.id,
                  title: s.title,
                  completed: false,
                ))
            .toList(),
      ));

      switch (frequency) {
        case TaskFrequency.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case TaskFrequency.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
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
          throw UnimplementedError();
      }
    }

    await batch.commit();
    return createdInstances;
  }

  Future<TaskTemplate> createTaskTemplate({
    required String userId,
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    required int priority,
    List<DateTime> reminders = const [],
    List<SubTaskTemplate> subtasks = const [],
    String? description,
  }) async {
    final taskTemplateRef = firestore.collection('taskTemplates').doc();
    await taskTemplateRef.set({
      'userId': userId,
      'title': title,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'subtasks': subtasks
          .map((s) => {
                'id': s.id,
                'title': s.title,
              })
          .toList(),
      'priority': priority,
      if (description != null) 'description': description,
    });
    final doc = await taskTemplateRef.get();
    return TaskTemplate.fromDoc(doc);
  }

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

  Future<TaskTemplate> getTaskTemplateById({
    required String taskTemplateId,
  }) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('taskTemplates')
        .doc(taskTemplateId)
        .get();

    return TaskTemplate.fromDoc(doc);
  }

  Future<List<TaskInstance>> getTaskInstances(
      {required DateTime selectedDate,
      required String userId,
      required String taskTemplateId}) async {
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
        .where(
          'taskTemplateId',
          isEqualTo: taskTemplateId,
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
    List<TaskTemplate> taskTemplates = await fetchTaskTemplates(userId: userId);
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

  Future<TaskTemplate> updateTaskTemplate({
    required String taskTemplateId,
    required String userId,
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<SubTaskTemplate> subtasks = const [],
    int? priority,
  }) async {
    final taskTemplateRef =
        firestore.collection('taskTemplates').doc(taskTemplateId);
    await taskTemplateRef.update({
      'userId': userId,
      'title': title,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'subtasks': subtasks
          .map((s) => {'id': s.id, 'title': s.title, 'completed': false})
          .toList(),
      if (priority != null) 'priority': priority,
    });

    final doc = await taskTemplateRef.get();
    return TaskTemplate.fromDoc(doc);
  }

  Future<List<TaskInstance>> updateRecurringTaskInstances({
    required String userId,
    required String taskTemplateId,
    required DateTime startDate,
    required TaskFrequency frequency,
  }) async {
    WriteBatch batch = firestore.batch();

    final existingDocs = await firestore
        .collection("taskInstances")
        .where("taskTemplateId", isEqualTo: taskTemplateId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .orderBy('date')
        .get();

    final existingInstances = existingDocs.docs;

    final daysAhead = frequency == TaskFrequency.daily
        ? 30
        : frequency == TaskFrequency.weekly
            ? 8
            : frequency == TaskFrequency.monthly
                ? 4
                : frequency == TaskFrequency.yearly
                    ? 2
                    : 1;

    List<TaskInstance> updatedInstances = [];
    DateTime currentDate = startDate;

    for (int i = 0; i < daysAhead; i++) {
      final instance = TaskInstance(
        id: existingInstances.length > i
            ? existingInstances[i].id
            : firestore.collection('taskInstances').doc().id,
        userId: userId,
        taskTemplateId: taskTemplateId,
        date: currentDate,
        completed: existingInstances.length > i
            ? existingInstances[i].data()['completed'] ?? false
            : false,
        completedAt: existingInstances.length > i
            ? (existingInstances[i].data()['completedAt'] != null
                ? (existingInstances[i].data()['completedAt'] as Timestamp)
                    .toDate()
                : null)
            : null,
      );

      updatedInstances.add(instance);

      if (existingInstances.length > i) {
        batch.update(existingInstances[i].reference, instance.toJson());
      } else {
        final docRef = firestore.collection('taskInstances').doc(instance.id);
        batch.set(docRef, instance.toJson());
      }

      switch (frequency) {
        case TaskFrequency.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case TaskFrequency.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
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
          throw UnimplementedError();
      }
    }

    if (existingInstances.length > daysAhead) {
      for (int i = daysAhead; i < existingInstances.length; i++) {
        batch.delete(existingInstances[i].reference);
      }
    }

    await batch.commit();
    return updatedInstances;
  }
}
