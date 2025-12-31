// lib/features/tasks/domain/repositories/task_repository.dart
import 'package:dartz/dartz.dart';
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';

import '../../../home/data/models/task_summary_model.dart';
abstract class TaskRepository {
  Future<Either<Failure, TaskSummaryModel>> getTaskSummary();
  Future<Either<Failure, List<TaskModel>>> getTasks(int page, int limit);
  Future<Either<Failure, void>> createTask(Map<String, dynamic> taskData);

}