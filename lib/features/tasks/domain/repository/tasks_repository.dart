import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';

abstract class TasksRepository {
  Future<List<Task>> getAllTasks();
  Future<Task> createNewTask(TaskData newTaskData);
  Future<Task> editTask(TaskData newTaskData);
  Future<void> deleteTask(DeleteTaskData deleteTaskData);
}
