import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';

class UpdateTaskInstance {
  final TasksRepository repository;

  UpdateTaskInstance(this.repository);

  Future<Task> call(UpdateTaskInstanceData taskData) async {
    return await repository.editTaskInstance(taskData);
  }
}
