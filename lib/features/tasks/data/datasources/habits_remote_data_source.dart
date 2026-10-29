import 'dart:developer';

import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
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
    await client.delete(
      '/habits/${deleteTaskData.taskId}',
    );
  }

  @override
  Future<TaskModel> editTask(UpdateTaskData updateTaskData) async {
    final response = await client.patch(
      '/habits/${updateTaskData.taskId}${_dateQuery(updateTaskData.date)}',
      data: updateTaskData.toJson(),
    );
    return TaskModel.fromJson(response.data);
  }

  String _dateQuery(DateTime? date) =>
      date == null ? '' : '?date=${DateFormat('yyyy-MM-dd').format(date)}';

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
  Future<TaskModel> syncSubtasks({
    required String taskId,
    required List<SubtaskState> subtasks,
    required DateTime date,
  }) async {
    final response = await client.post(
      '/habits/$taskId/subtasks/sync?date=${DateFormat('yyyy-MM-dd').format(date)}',
      data: {
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      },
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
