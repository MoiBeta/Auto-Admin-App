import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';

class UpdateTaskData {
  String taskId;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<String>? subTasks;
  int? priority;
  DateTime? reminderDate;

  UpdateTaskData({
    required this.taskId,
    required this.title,
    required this.startDate,
    required this.frequency,
    this.priority,
    this.description,
    this.subTasks,
    this.reminderDate,
  });

  toJson() {
    return {
      'name': title,
      'description': description,
      'frequency': frequency.name.toUpperCase(),
      if (priority != null) 'priority': priority,
      if (subTasks != null && subTasks!.isNotEmpty)
        'subTasks': subTasks
            ?.map((e) => {
                  'title': e,
                })
            .toList(),
      if (reminderDate != null)
        'reminder': {
          'timeMinutes':
              reminderDate!.toUtc().hour * 60 + reminderDate!.toUtc().minute,
          'enabled': true,
        },
    };
  }
}
