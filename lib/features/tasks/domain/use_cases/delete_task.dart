import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';

class DeleteTask {
  final TasksRepository repository;
  DeleteTask(this.repository);

  Future<void> call(DeleteTaskData deleteTaskData) async {
    return await repository.deleteTask(deleteTaskData);
  }
}
