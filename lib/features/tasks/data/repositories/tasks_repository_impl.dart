import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';

class TaskRepositoryImpl extends TasksRepository {
  final TasksDataSource tasksDataSource;

  TaskRepositoryImpl(this.tasksDataSource);

  @override
  Future<Task> createNewTask(TaskData newTaskData) async {
    TaskModel taskModel = await tasksDataSource.createNewTask(newTaskData);
    return taskModel.toEntity();
  }

  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) {
    return tasksDataSource.deleteTask(deleteTaskData);
  }

  @override
  Future<Task> editTaskTemplate(UpdateTaskTemplateData updateTaskData) async {
    TaskModel taskModel =
        await tasksDataSource.editTaskTemplate(updateTaskData);
    return taskModel.toEntity();
  }

  @override
  Future<List<Task>> getAllTasks(DateTime date) {
    tasksDataSource.checkAndCreateUpcomingInstances();
    return tasksDataSource.getAllTasks(date).then((tasks) {
      return tasks.map((task) => task.toEntity()).toList();
    });
  }

  @override
  Future<Task> editTaskInstance(UpdateTaskInstanceData updateTaskData) async {
    TaskModel taskModel =
        await tasksDataSource.editTaskInstance(updateTaskData);
    return taskModel.toEntity();
  }
}
