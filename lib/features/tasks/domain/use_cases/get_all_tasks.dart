import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';

class GetAllTasks {
  final TasksRepository repository;

  GetAllTasks(this.repository);

  Future<List<Task>> call(
    DateTime date,
  ) async {
    return await repository.getAllTasks(date);
  }
}
