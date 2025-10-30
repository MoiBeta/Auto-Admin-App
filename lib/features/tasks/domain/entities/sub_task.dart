class Subtask {
  String id;
  String title;
  bool completed;

  Subtask({
    required this.id,
    required this.title,
    required this.completed,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}
