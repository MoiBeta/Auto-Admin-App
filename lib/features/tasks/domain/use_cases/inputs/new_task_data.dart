import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:intl/intl.dart';

class NewTaskData {
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  int priority;
  List<String>? subTasks;
  DateTime? reminderDate;

  /// IANA time zone of the device, sent with the reminder.
  String? timezone;

  NewTaskData({
    required this.title,
    required this.startDate,
    required this.frequency,
    required this.priority,
    this.description,
    this.subTasks,
    this.reminderDate,
    this.timezone,
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
      if (reminderDate != null)
        'reminder': {
          // Local time + device offset, so the backend evaluates the reminder
          // against the user's local day.
          'timeMinutes': reminderDate!.hour * 60 + reminderDate!.minute,
          'utcOffsetMinutes': reminderDate!.timeZoneOffset.inMinutes,
          // IANA zone, so the reminder follows daylight saving time changes.
          if (timezone != null) 'timezone': timezone,
          'enabled': true,
        },
    };
  }
}
