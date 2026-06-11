import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';

class ToggleTask {
  final TasksRepository repository;

  ToggleTask(this.repository);

  Future<Task> call(ToggleTaskData data) async {
    return await repository.toggleTask(data);
  }
}
