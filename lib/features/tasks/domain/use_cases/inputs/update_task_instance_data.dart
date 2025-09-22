import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';

class UpdateTaskInstanceData {
  final String instanceId;
  final bool completed;
  final DateTime? completedAt;
  final List<Subtask> subtaskStates;

  UpdateTaskInstanceData({
    required this.instanceId,
    required this.completed,
    this.completedAt,
    this.subtaskStates = const [],
  });
}
