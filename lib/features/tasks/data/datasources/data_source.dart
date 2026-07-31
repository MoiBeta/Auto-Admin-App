import 'package:auto_admin_app/features/tasks/data/models/task_model.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/delete_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/new_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/toggle_task_data.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/inputs/update_task_data.dart';

abstract class TasksDataSource {
  Future<List<TaskModel>> getAllTasks(DateTime date);

  Future<TaskModel> createNewTask(NewTaskData newTaskData);

  Future<TaskModel> editTask(UpdateTaskData newTaskData);

  Future<void> deleteTask(DeleteTaskData deleteTaskData);

  Future<TaskModel> toggleTask(ToggleTaskData data);

  Future<TaskModel> syncSubtasks({
    required String taskId,
    required List<SubtaskState> subtasks,
    required DateTime date,
  });
}

class SubtaskState {
  final String sourceSubTaskId;
  final bool completed;

  SubtaskState({required this.sourceSubTaskId, required this.completed});

  Map<String, dynamic> toJson() => {
        'sourceSubTaskId': sourceSubTaskId,
        'completed': completed,
      };
}
