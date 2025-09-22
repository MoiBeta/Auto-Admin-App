import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';

class UpdateTaskTemplate {
  final TasksRepository repository;

  UpdateTaskTemplate(this.repository);

  Future<Task> call(UpdateTaskTemplateData taskData) async {
    return await repository.editTaskTemplate(taskData);
  }
}
