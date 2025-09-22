import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';

class DeleteTaskData {
  String templateId;
  String instanceId;
  DeleteScope scope;
  DateTime? referenceDate;

  DeleteTaskData({
    required this.templateId,
    required this.instanceId,
    required this.scope,
    this.referenceDate,
  });
}
