class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final DateTime? startTaskAt;
  final DateTime? endTaskAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.startTaskAt,
    this.endTaskAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'to_do',
      startTaskAt: json['startTaskAt'] != null 
          ? DateTime.parse(json['startTaskAt']) 
          : null,
      endTaskAt: json['endTaskAt'] != null 
          ? DateTime.parse(json['endTaskAt'])  : null, 
    );
  }
}