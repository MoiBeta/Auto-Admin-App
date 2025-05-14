import 'dart:async';

import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/data/models/sub_task.dart';
import 'package:auto_admin_app/data/models/task_instance.dart';
import 'package:auto_admin_app/data/models/task_template.dart';
import 'package:auto_admin_app/data/repositories/task_repository.dart';
import 'package:auto_admin_app/state/auth_provider.dart';
import 'package:auto_admin_app/state/repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'home_provider.g.dart';

@Riverpod(keepAlive: true)
class HomeNotifier extends _$HomeNotifier {
  late TaskRepository taskRepository;
  List<TaskTemplate> taskTemplates = [];
  String? userId;

  @override
  List<TaskInstance> build() {
    getTaskInstances(ref.watch(selectedDateProvider));
    checkAndGenerateTaskInstances();
    taskRepository = ref.read(taskRepositoryProvider);
    userId = ref.read(authNotifierProvider)!.uid;
    return [];
  }

  Future<void> getTaskInstances(DateTime selectedDate) async {
    Future.microtask(() async {
      state = await taskRepository.getTaskInstances(
        selectedDate: selectedDate,
        userId: userId ?? '',
      );
    });
  }

  Future<void> createRecurringTask({
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<Subtask> subtasks = const [],
    int daysAhead = 30,
    String? taskTemplateId,
  }) async {
    ref.read(isLoadingProvider.notifier).setLoading(true);

    taskTemplateId ??= await taskRepository.createTaskTemplate(
      userId: userId!,
      title: title,
      frequency: frequency,
      startDate: startDate,
      priority: taskTemplates.length + 2,
    );

    await taskRepository.createRecurringTaskInstances(
      userId: userId!,
      taskTemplateId: taskTemplateId,
      startDate: startDate,
      frequency: frequency,
    );

    await getTaskInstances(ref.watch(selectedDateProvider));
    ref.read(isLoadingProvider.notifier).setLoading(false);
  }

  Future<void> completeTask(
      {required String taskInstanceId, required bool completed}) async {
    List<TaskInstance> instances = List<TaskInstance>.from(state);

    int index =
        instances.indexWhere((instance) => instance.id == taskInstanceId);
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

    taskTemplates = taskTemplates
        .where((template) => template.id != taskTemplateId)
        .toList();

    state = List.from(state.where(
        (taskInstance) => taskInstance.taskTemplateId != taskTemplateId));

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
    reorderTaskTemplate(oldIndex, newIndex);
  }

  Future<void> reorderTaskTemplate(int oldIndex, int newIndex) async {
    final templateItem = taskTemplates.removeAt(oldIndex);
    taskTemplates.insert(newIndex, templateItem);
    await updateTasksInDatabase();
  }

  Future<void> updateTasksInDatabase() async {
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
    return taskRepository.fetchTaskTemplates(
      userId: userId!,
    );
  }

  Future<void> checkAndGenerateTaskInstances() async {
    List<TaskTemplate> templates = await fetchTaskTemplates();

    for (TaskTemplate template in templates) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('taskInstances')
          .where(
            'taskTemplateId',
            isEqualTo: template.id,
          )
          .where('date', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('date')
          .get();

      TaskInstance taskInstance = TaskInstance.fromDoc(snapshot.docs.last);

      if (template.frequency == TaskFrequency.daily &&
          snapshot.docs.length < 20) {
        await createRecurringTask(
          title: template.title,
          frequency: template.frequency,
          startDate: taskInstance.date.add(const Duration(days: 1)),
          daysAhead: DateTime.now()
              .add(
                const Duration(
                  days: 30,
                ),
              )
              .difference(taskInstance.date)
              .inDays,
          taskTemplateId: template.id,
        );
      }

      if (template.frequency == TaskFrequency.weekly &&
          snapshot.docs.length < 3) {
        await createRecurringTask(
          title: template.title,
          frequency: template.frequency,
          startDate: taskInstance.date.add(const Duration(days: 1)),
          daysAhead: 4,
          taskTemplateId: template.id,
        );
      }
    }
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

@riverpod
class IsLoading extends _$IsLoading {
  @override
  bool build() => false;

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}
