import 'dart:developer';

import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_sub_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';
import 'package:intl/intl.dart';

class HabitsRemoteDataSource implements TasksDataSource {
  final DioClient client;

  HabitsRemoteDataSource({required this.client});

  @override
  Future<TaskModel> createNewTask(NewTaskData newTaskData) async {
    final response = await client.post(
      '/habits',
      data: newTaskData.toJson(),
    );
    return TaskModel.fromJson(response.data);
  }

  @override
  Future<void> deleteTask(DeleteTaskData deleteTaskData) async {
    await client.post(
      '/habits/${deleteTaskData.taskId}',
    );
  }

  @override
  Future<TaskModel> editTask(UpdateTaskData updateTaskData) async {
    final response = await client.post(
      '/habits/${updateTaskData.taskId}',
    );

    return TaskModel.fromJson(response.data);
  }

  @override
  Future<List<TaskModel>> getAllTasks(DateTime date) async {
    final response = await client.get(
      '/habits?date=${DateFormat('yyyy-MM-dd').format(date)}',
    );

    log(response.data.toString());

    return (response.data as List<dynamic>)
        .map((e) => TaskModel.fromJson(e))
        .toList();
  }

  @override
  Future<TaskModel> toggleSubTask(ToggleSubTaskData data) async {
    final response = await client.post(
      '/habits/${data.taskId}/subtasks/${data.subTaskId}/toggle?date=${DateFormat('yyyy-MM-dd').format(data.completedAt)}',
    );
    return TaskModel.fromJson(response.data);
  }

  @override
  Future<TaskModel> toggleTask(ToggleTaskData data) async {
    final response = await client.post(
      '/habits/${data.taskId}/toggle?date=${DateFormat('yyyy-MM-dd').format(data.completedAt)}',
    );
    return TaskModel.fromJson(response.data);
  }
}
