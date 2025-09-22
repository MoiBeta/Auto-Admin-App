class SubTaskTemplate {
  String id;
  String title;

  SubTaskTemplate({
    required this.id,
    required this.title,
  });

  factory SubTaskTemplate.fromMap(Map<String, dynamic> map) => SubTaskTemplate(
        id: map['id'],
        title: map['title'],
      );
}
