
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:smart_task_manager/features/home/data/models/task_summary_model.dart';
import 'package:smart_task_manager/features/tasks/data/datasources/task_local_ds.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_ds.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });
@override
  Future<Either<Failure, void>> createTask(Map<String, dynamic> taskData) async {
    try {
      DateTime? startAt;
      if (taskData['startDate'] != null && taskData['startTime'] != null) {
        try {
          startAt = DateTime.parse("${taskData['startDate']} ${taskData['startTime']}"); // Simple Combine
        } catch (_) {}
      }
      // 1.  ALWAYS Save to Local DB First (Offline Save)
    final localId = await localDataSource.insertTask(
      TasksCompanion(
        title: drift.Value(taskData['title']),
        description: drift.Value(taskData['description']),
        isCompleted: const drift.Value(false),
        isSynced: const drift.Value(false), 
        serverId: const drift.Value(null),
        status: const drift.Value('pending'),
          startTaskAt: drift.Value(startAt),
      )
    );

      // 2.  Check Internet & Sync
      if (await networkInfo.isConnected) {
        try {
        
          final serverId = await remoteDataSource.createTask(taskData); 
         await localDataSource.updateTaskSyncStatus(localId, serverId);
          
        } catch (e) {

          debugPrint("API failed but saved locally: $e");
        }
      }

      // 3. Always Return Success (Kyunki Local Save ho gaya)
      return const Right(null);

    } catch (e) {
     debugPrint("Local save failed: $e");
      return Left(CacheFailure("Local Save Failed: $e"));
    }
  }
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
        final remoteTasks = await remoteDataSource.getTasks(page, limit);
        return Right(remoteTasks);
      } catch (e) {
        // Agar Server fail hua, toh bhi Local try kar sakte hain (Optional)
        return Left(ServerFailure(e.toString()));
      }
    }
    else {
      try {
        final localTasks = await localDataSource.getAllTasks();
        
        // Drift Task ko TaskModel mein convert karein
        final tasks = localTasks.map((t) => TaskModel(
          id: t.serverId ?? t.id.toString(), // ServerID prefer karein
          title: t.title,
          description: t.description,
          status: t.status, // Ab DB mein status hai
          startTaskAt: t.startTaskAt,
        )).toList();

        return Right(tasks);
      } catch (e) {
        return Left(CacheFailure("No local data found"));
      }
    }
}

}