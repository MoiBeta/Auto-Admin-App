import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';

class UpdateTask {
  final TasksRepository repository;
  UpdateTask(this.repository);

  Future<Task> call(TaskData taskData) async {
    return await repository.editTask(taskData);
  }
}
