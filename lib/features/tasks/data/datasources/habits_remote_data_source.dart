import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_instance_data.dart';

class HabitsRemoteDataSource implements TasksDataSource {
  final DioClient client;

  HabitsRemoteDataSource({required this.client});

  @override
  Future<void> checkAndCreateUpcomingInstances() {
    // TODO: implement checkAndCreateUpcomingInstances
    throw UnimplementedError();
  }

  @override
  Future<TaskModel> createNewTask(TaskData newTaskData) {
    // TODO: implement createNewTask
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) {
    // TODO: implement deleteTask
    throw UnimplementedError();
  }

  @override
  Future<TaskModel> editTaskInstance(UpdateTaskInstanceData newTaskData) {
    // TODO: implement editTaskInstance
    throw UnimplementedError();
  }

  @override
  Future<TaskModel> editTaskTemplate(UpdateTaskTemplateData newTaskData) {
    // TODO: implement editTaskTemplate
    throw UnimplementedError();
  }

  @override
  Future<List<TaskModel>> getAllTasks(DateTime date) {
    // TODO: implement getAllTasks
    throw UnimplementedError();
  }
}
