class TaskData {
  String title;
  String? description;
  DateTime startDate;
  List<String>? subTask;

  TaskData({
    required this.title,
    required this.startDate,
    this.description,
    this.subTask,
  });
}
