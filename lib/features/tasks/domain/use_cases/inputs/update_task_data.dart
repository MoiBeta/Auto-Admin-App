import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:intl/intl.dart';

class UpdateTaskData {
  String taskId;
  String title;
  String? description;
  DateTime startDate;
  TaskFrequency frequency;
  List<String>? subTasks;
  int? priority;
  DateTime? reminderDate;

  /// IANA time zone of the device, sent with the reminder.
  String? timezone;

  /// New day the habit starts (weekly/monthly/yearly habits repeat on it).
  /// Null keeps the current one.
  DateTime? newStartDate;

  /// Disables the existing reminder. Ignored when [reminderDate] is set.
  bool removeReminder;

  /// Day being viewed; the response reflects the completion state of that day.
  DateTime? date;

  UpdateTaskData({
    required this.taskId,
    required this.title,
    required this.startDate,
    required this.frequency,
    this.priority,
    this.description,
    this.subTasks,
    this.reminderDate,
    this.removeReminder = false,
    this.timezone,
    this.newStartDate,
    this.date,
  });

  toJson() {
    return {
      'name': title,
      // Omitted fields keep their current value on the backend.
      if (description != null) 'description': description,
      'frequency': frequency.name.toUpperCase(),
      if (newStartDate != null)
        'date': DateFormat('yyyy-MM-dd').format(newStartDate!),
      if (priority != null) 'priority': priority,
      // An empty list removes all subtasks; null leaves them unchanged.
      if (subTasks != null)
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
        }
      else if (removeReminder)
        // timeMinutes is required by the backend; its value is irrelevant here.
        'reminder': {'timeMinutes': 0, 'enabled': false},
    };
  }
}
