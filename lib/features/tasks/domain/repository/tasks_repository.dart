import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_sub_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';

abstract class TasksRepository {
  Future<List<Task>> getAllTasks(DateTime date);

  Future<Task> createNewTask(NewTaskData newTaskData);

  Future<Task> editTask(UpdateTaskData updateTaskData);

  Future<void> deleteTask(DeleteTaskData deleteTaskData);

  Future<Task> toggleTask(ToggleTaskData data);

  Future<Task> toggleSubTask(ToggleSubTaskData data);
}
