import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';

class DeleteTaskData {
  String taskId;
  DeleteScope scope;
  DateTime? referenceDate;

  DeleteTaskData({
    required this.taskId,
    required this.scope,
    this.referenceDate,
  });
}
