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

  /// The day being viewed, and the device's current day: a pending one-time
  /// task is shown only on the latter.
  String _dateQuery(DateTime? date) {
    final format = DateFormat('yyyy-MM-dd');
    final today = 'today=${format.format(DateTime.now())}';
    return date == null ? '?$today' : '?date=${format.format(date)}&$today';
  }

  @override
  Future<List<TaskModel>> getAllTasks(DateTime date) async {
    final response = await client.get(
      '/habits${_dateQuery(date)}',
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
      '/habits/$taskId/subtasks/sync${_dateQuery(date)}',
      data: {
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      },
    );
    return TaskModel.fromJson(response.data);
  }

  @override
  Future<TaskModel> toggleTask(ToggleTaskData data) async {
    final response = await client.post(
      '/habits/${data.taskId}/toggle${_dateQuery(data.completedAt)}',
    );
    return TaskModel.fromJson(response.data);
  }
}
