import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/data/models/sub_task.dart';
import 'package:auto_admin_app/data/models/task_instance.dart';
import 'package:auto_admin_app/data/models/task_template.dart';

abstract class TaskRepository {
  Future<List<TaskInstance>> getTaskInstances({
    required DateTime selectedDate,
    required String userId,
  });
  Future<List<TaskTemplate>> fetchTaskTemplates({
    required String userId,
  });
  Future<String> createTaskTemplate({
    required String userId,
    required String title,
    required TaskFrequency frequency,
    required DateTime startDate,
    List<DateTime> reminders = const [],
    List<Subtask> subtasks = const [],
    int priority = 0,
  });
  Future<void> createRecurringTaskInstances({
    required String userId,
    required String taskTemplateId,
    required DateTime startDate,
    required TaskFrequency frequency,
    int daysAhead = 30,
  });

}