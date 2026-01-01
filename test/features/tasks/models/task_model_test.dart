import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';

void main() {
  group('TaskModel', () {
    test('fromJson creates valid TaskModel', () {
      final json = {
        'id': '1',
        'title': 'Test Task',
        'status': 'pending',
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, '1');
      expect(task.title, 'Test Task');
      expect(task.status, 'pending');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '2',
        'title': 'No Description',
        'status': 'processing',
      };

      final task = TaskModel.fromJson(json);

      expect(task.id, '2');
      expect(task.title, 'No Description');
      expect(task.description, isNull);
      expect(task.status, 'processing');
      expect(task.startTaskAt, isNull);
      expect(task.endTaskAt, isNull);
    });

    test('fromJson parses DateTime fields', () {
      final json = {
        'id': '3',
        'title': 'Date Task',
        'status': 'pending',
        'startTaskAt': '2024-06-01T12:00:00.000',
        'endTaskAt': '2024-06-02T12:00:00.000',
      };

      final task = TaskModel.fromJson(json);

      expect(task.startTaskAt, DateTime.parse('2024-06-01T12:00:00.000'));
      expect(task.endTaskAt, DateTime.parse('2024-06-02T12:00:00.000'));
    });

    // Add toJson method to TaskModel before enabling this test
    test('toJson returns valid map', () {
      final task = TaskModel(
        id: '1',
        title: 'Demo Task',
        status: 'completed',
      );
    
      final json = task.toJson();
    
      expect(json['title'], 'Demo Task');
      expect(json['status'], 'completed');
    });
  });
}