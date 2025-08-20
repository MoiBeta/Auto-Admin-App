
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';

class CreateNewTask {
  final TasksRepository repository;
  CreateNewTask(this.repository);

  Future<Task> call(TaskData newTaskData) async {
    return await repository.createNewTask(newTaskData);
  }
}
