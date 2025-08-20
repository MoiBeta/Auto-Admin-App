import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';

class GetAllTasks {
  final TasksRepository repository;
  GetAllTasks(this.repository);

  Future<List<Task>> call(TaskData taskData) async {
    return await repository.getAllTasks();
  }
}
