class TaskSummaryModel {
  final int todo;
  final int pending;
  final int completed;
  final int canceled;

  TaskSummaryModel({
    required this.todo,
    required this.pending,
    required this.completed,
    required this.canceled,
  });

  factory TaskSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary']; 
    return TaskSummaryModel(
      todo: summary['to_do'] ?? 0,
      pending: summary['pending'] ?? 0,
      completed: summary['completed'] ?? 0,
      canceled: summary['canceled'] ?? 0,
    );
  }
}