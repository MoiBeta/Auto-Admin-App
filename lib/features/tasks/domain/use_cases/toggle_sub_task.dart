import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_sub_task_data.dart';

class ToggleSubTask {
  final TasksRepository repository;

  ToggleSubTask(this.repository);

  Future<Task> call(ToggleSubTaskData data) async {
    return await repository.toggleSubTask(data);
  }
}
