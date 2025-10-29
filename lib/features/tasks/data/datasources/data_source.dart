import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';

abstract class TasksDataSource {
  Future<List<TaskModel>> getAllTasks(DateTime date);

  Future<TaskModel> createNewTask(TaskData newTaskData);

  Future<TaskModel> editTaskTemplate(UpdateTaskTemplateData newTaskData);

  Future<TaskModel> editTaskInstance(UpdateTaskInstanceData newTaskData);

  Future<void> deleteTask(DeleteTaskData deleteTaskData);

  Future<void> checkAndCreateUpcomingInstances();
}
