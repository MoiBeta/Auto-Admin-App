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
  Future<List<TaskInstance>> build() async {
    taskRepository = ref.read(taskRepositoryProvider);
    userId = ref.read(authNotifierProvider)!.user?.uid;
    List<TaskInstance> tasks =
        await getTaskInstances(ref.watch(selectedDateProvider));
    checkAndGenerateTaskInstances();
    return tasks;
  }

  Future<List<TaskInstance>> getTaskInstances(DateTime selectedDate) async {
    return taskRepository.getTaskInstances(
      selectedDate: selectedDate,
      userId: userId ?? '',
    );
  }

  Future<void> refreshTasks(DateTime date) async {
    state = const AsyncLoading();

    try {
      final tasks = await getTaskInstances(date);
      state = AsyncData(tasks);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createEditRecurringTask({
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<Subtask> subtasks = const [],
    int daysAhead = 30,
    String? taskTemplateId,
    bool? mustUpdate,
  }) async {
    ref.read(isLoadingProvider.notifier).setLoading(true);
    taskTemplates = await fetchTaskTemplates();

    if (taskTemplateId == null) {
      taskTemplateId = await taskRepository.createTaskTemplate(
        userId: userId!,
        title: title,
        frequency: frequency,
        startDate: startDate,
        priority: taskTemplates.length + 1,
      );

      await taskRepository.createRecurringTaskInstances(
        userId: userId!,
        taskTemplateId: taskTemplateId,
        startDate: startDate,
        frequency: frequency,
      );
    } else if (mustUpdate ?? false) {
      await taskRepository.updateTaskTemplate(
        taskTemplateId: taskTemplateId,
        userId: userId!,
        title: title,
        frequency: frequency,
        startDate: startDate,
        priority: taskTemplates.length + 1,
      );

      await taskRepository.updateRecurringTaskInstances(
        userId: userId!,
        taskTemplateId: taskTemplateId,
        startDate: startDate,
        frequency: frequency,
      );
    }

    state = AsyncData(
      await getTaskInstances(
        ref.watch(selectedDateProvider),
      ),
    );
    ref.read(isLoadingProvider.notifier).setLoading(false);
  }

  Future<void> completeTask(
      {required String taskInstanceId, required bool completed}) async {
    List<TaskInstance> instances = List<TaskInstance>.from(state.value ?? []);

    int index =
        instances.indexWhere((instance) => instance.id == taskInstanceId);
    instances[index].completed = completed;

    state = AsyncValue.data(instances);

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
    taskRepository.deleteRecurringTask(taskTemplateId);

    taskTemplates = taskTemplates
        .where((template) => template.id != taskTemplateId)
        .toList();

    state = AsyncValue.data(
      List.from(
        (state.value ?? []).where(
            (taskInstance) => taskInstance.taskTemplateId != taskTemplateId),
      ),
    );
  }

  Future<void> updateTaskPriorities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    List<TaskInstance> instances = List.from(state.value ?? []);

    final taskItem = instances.removeAt(oldIndex);
    instances.insert(newIndex, taskItem);
    state = AsyncValue.data(instances);
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
    taskTemplates = await fetchTaskTemplates();

    if (taskTemplates.isNotEmpty) {
      for (TaskTemplate template in taskTemplates) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('taskInstances')
            .where(
              'taskTemplateId',
              isEqualTo: template.id,
            )
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date')
            .get();

        TaskInstance? taskInstance = snapshot.docs.isNotEmpty
            ? TaskInstance.fromDoc(snapshot.docs.last)
            : null;

        if (template.frequency == TaskFrequency.daily &&
            snapshot.docs.length < 20) {
          await createEditRecurringTask(
            title: template.title,
            frequency: template.frequency,
            startDate: taskInstance != null
                ? taskInstance.date.add(const Duration(days: 1))
                : DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day),
            daysAhead: DateTime.now()
                .add(
                  const Duration(
                    days: 30,
                  ),
                )
                .difference(
                    taskInstance != null ? taskInstance.date : DateTime.now())
                .inDays,
            taskTemplateId: template.id,
          );
        }

        if (template.frequency == TaskFrequency.weekly &&
            snapshot.docs.length < 3) {
          await createEditRecurringTask(
            title: template.title,
            frequency: template.frequency,
            startDate: taskInstance != null
                ? taskInstance.date.add(const Duration(days: 1))
                : DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day),
            daysAhead: 4,
            taskTemplateId: template.id,
          );
        }
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
    ref.read(homeNotifierProvider.notifier).refreshTasks(date);
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
