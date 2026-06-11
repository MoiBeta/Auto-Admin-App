class ToggleSubTaskData {
  final String taskId;
  final String subTaskId;
  final DateTime completedAt;

  ToggleSubTaskData({
    required this.taskId,
    required this.subTaskId,
    required this.completedAt,
  });
}
