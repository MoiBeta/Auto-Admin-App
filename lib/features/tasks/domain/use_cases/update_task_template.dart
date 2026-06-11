import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';

class UpdateTask {
  final TasksRepository repository;

  UpdateTask(this.repository);

  Future<Task> call(UpdateTaskData taskData) async {
    return await repository.editTask(taskData);
  }
}
