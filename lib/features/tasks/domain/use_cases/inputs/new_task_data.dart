import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:intl/intl.dart';

class NewTaskData {
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  int priority;
  List<String>? subTasks;

  NewTaskData({
    required this.title,
    required this.startDate,
    required this.frequency,
    required this.priority,
    this.description,
    this.subTasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': title,
      'description': description,
      'date': DateFormat('yyyy-MM-dd').format(startDate),
      'frequency': frequency.name.toUpperCase(),
      'priority': priority,
      'subTasks': subTasks
          ?.map((e) => {
                'title': e,
              })
          .toList(),
    };
  }
}
