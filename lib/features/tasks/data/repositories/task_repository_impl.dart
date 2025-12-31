
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
      // 1.  ALWAYS Save to Local DB First (Offline Save)
      final localId = await localDataSource.insertTask(
        TasksCompanion(
          title: drift.Value(taskData['title']),
          description: drift.Value(taskData['description']),
          isCompleted: const drift.Value(false),
          isSynced: const drift.Value(false), // Abhi sync nahi hua
          serverId: const drift.Value(null),
        ),
      );

      // 2.  Check Internet & Sync
      if (await networkInfo.isConnected) {
        try {
          // Server par bhejo
          final response = await remoteDataSource.createTask(taskData);
          
          // Agar server ID return karta hai (Ex: response['task']['id'])
          // Toh hum local DB update karenge. 
          // Assuming response mein serverId hai (agar nahi hai to API response modify karna padega)
          // String serverId = response['id']; 
          // await localDataSource.updateTaskSyncStatus(localId, serverId);
          
        } catch (e) {

          debugPrint("API failed but saved locally: $e");
        }
      }

      // 3. Always Return Success (Kyunki Local Save ho gaya)
      return const Right(null);

    } catch (e) {
      // Agar Local DB hi fail ho gaya, tabhi error dikhao
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
      final tasks = await remoteDataSource.getTasks(page, limit);
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  } else {
     
    return Left(const NetworkFailure("No Internet Connection"));
  }
}

// @override
// Future<Either<Failure, void>> createTask(Map<String, dynamic> taskData) async {
//   if (await networkInfo.isConnected) {
//     try {
//       await remoteDataSource.createTask(taskData);
//       return const Right(null);
//     } catch (e) {
//       return Left(ServerFailure(e.toString()));
//     }
//   } else {
//     return Left(const NetworkFailure("No Internet Connection"));
//   }
// }
}