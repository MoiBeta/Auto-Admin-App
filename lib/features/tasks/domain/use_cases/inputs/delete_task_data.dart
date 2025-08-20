import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';

class DeleteTaskData {
  String id;
  DeleteScope scope;

  DeleteTaskData({
    required this.id,
    required this.scope,
});
}