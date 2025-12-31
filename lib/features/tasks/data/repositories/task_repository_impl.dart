// lib/features/tasks/data/repositories/task_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:smart_task_manager/features/home/data/models/task_summary_model.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_ds.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TaskSummaryModel>> getTaskSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDataSource.getTaskSummary();
        return Right(summary);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure("No Internet Connection"));
    }
  }
  @override
Future<Either<Failure, List<TaskModel>>> getTasks(int page, int limit) async {
  if (await networkInfo.isConnected) {
    try {
      final tasks = await remoteDataSource.getTasks(page, limit);
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  } else {
     
    return Left(const NetworkFailure("No Internet Connection"));
  }
}

@override
Future<Either<Failure, void>> createTask(Map<String, dynamic> taskData) async {
  if (await networkInfo.isConnected) {
    try {
      await remoteDataSource.createTask(taskData);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  } else {
    return Left(const NetworkFailure("No Internet Connection"));
  }
}
}