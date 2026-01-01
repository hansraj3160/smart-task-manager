import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../home/data/models/task_summary_model.dart';
import '../../domain/repositories/task_repository.dart';

import '../datasources/task_local_ds.dart';
import '../datasources/task_remote_ds.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final _storage = const FlutterSecureStorage();

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ---------------------------------------------------------------------------
  //  SYNC PENDING TASKS (Background Sync)
  // ---------------------------------------------------------------------------
@override
  Future<void> syncPendingTasks() async {
    if (await networkInfo.isConnected) {
      try {
        final pendingTasks = await localDataSource.getUnsyncedTasks();
        if (pendingTasks.isEmpty) return;

        String? userIdStr = await _storage.read(key: 'user_id');
        int userId = userIdStr != null ? int.parse(userIdStr) : 19;

        for (var task in pendingTasks) {
          try {
            // CASE 1: New Task (No Server ID) -> Create & Update
            if (task.serverId == null) {
              final Map<String, dynamic> taskData = {
                "userId": userId,
                "title": task.title,
                "description": task.description,
                "startDate": task.startTaskAt != null
                    ? DateFormat('yyyy-MM-dd').format(task.startTaskAt!) : null,
                "startTime": task.startTaskAt != null
                    ? DateFormat('HH:mm').format(task.startTaskAt!) : null,
                "endDate": task.endTaskAt != null
                    ? DateFormat('yyyy-MM-dd').format(task.endTaskAt!) : null,
                "endTime": task.endTaskAt != null
                    ? DateFormat('HH:mm').format(task.endTaskAt!) : null,
              };

              debugPrint("Creating New Task on Sync: ${task.title}");
              final serverId = await remoteDataSource.createTask(taskData);
              await localDataSource.updateTaskSyncStatus(task.id, serverId);

              // Update Status if needed
              await _syncTaskStatus(serverId, task.status);
            } 
            
            // CASE 2: Existing Task (Has Server ID) -> Update Status
            else {
              debugPrint("Updating Existing Task on Sync: ${task.title}");
              await _syncTaskStatus(task.serverId!, task.status);
              
              // Mark as Synced
              await localDataSource.updateTaskSyncStatus(task.id, task.serverId!);
            }
          } catch (e) {
            debugPrint("❌ Failed to sync task '${task.title}': $e");
          }
        }
      } catch (e) {
        debugPrint("Sync Error: $e");
      }
    }
  }

  // Helper Function: Smart Status Update
  Future<void> _syncTaskStatus(String serverId, String status) async {
    try {
      if (status == 'processing') {
        // Try Pending -> Processing (Action 1)
        try {
          await remoteDataSource.updateTaskStatus(serverId, 1);
        } catch (_) {
          // Ignore: Maybe already processing
        }
      } 
      else if (status == 'completed') {
        // Flow: Pending -> Processing -> Completed
        try { await remoteDataSource.updateTaskStatus(serverId, 1); } catch (_) {} 
        try { await remoteDataSource.updateTaskStatus(serverId, 2); } catch (_) {}
      } 
      else if (status == 'canceled') {
        // FIX: Try 'Pending -> Cancel' (Action 4) FIRST
        try {
          await remoteDataSource.updateTaskStatus(serverId, 4);
        } catch (e) {
          // If fail, Try 'Processing -> Cancel' (Action 3)
          try {
             await remoteDataSource.updateTaskStatus(serverId, 3);
          } catch (e2) {
             debugPrint("Could not cancel task (maybe already canceled): $e2");
          }
        }
      }
    } catch (e) {
      debugPrint("Status Sync Error: $e");
    }
  }

 
  //  CREATE TASK

  @override
  Future<Either<Failure, void>> createTask(Map<String, dynamic> taskData) async {
    try {
      // Parse Dates for Local DB
      DateTime? startAt;
      if (taskData['startDate'] != null && taskData['startTime'] != null) {
        try {
          startAt = DateTime.parse("${taskData['startDate']} ${taskData['startTime']}");
        } catch (_) {}
      }
      DateTime? endAt;
      if (taskData['endDate'] != null && taskData['endTime'] != null) {
        try {
          endAt = DateTime.parse("${taskData['endDate']} ${taskData['endTime']}");
        } catch (_) {}
      }

      // 1. Save to Local DB (Offline First)
      final localId = await localDataSource.insertTask(
        TasksCompanion(
          title: drift.Value(taskData['title']),
          description: drift.Value(taskData['description']),
          isCompleted: const drift.Value(false),
          isSynced: const drift.Value(false),
          serverId: const drift.Value(null),
          status: const drift.Value('to_do'), // Default status
          startTaskAt: drift.Value(startAt),
          endTaskAt: drift.Value(endAt),
        ),
      );

      // 2. Check Internet & Sync
      if (await networkInfo.isConnected) {
        try {
          final serverId = await remoteDataSource.createTask(taskData);
          await localDataSource.updateTaskSyncStatus(localId, serverId);
        } catch (e) {
          debugPrint("API failed but saved locally: $e");
        }
      }

      return const Right(null);
    } catch (e) {
      debugPrint("Local save failed: $e");
      return Left(CacheFailure("Local Save Failed: $e"));
    }
  }

  // ---------------------------------------------------------------------------
  // GET TASKS (With Caching)
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, List<TaskModel>>> getTasks(int page, int limit) async {
    // 1. Online -> Fetch & Cache
    if (await networkInfo.isConnected) {
      try {
        final remoteTasks = await remoteDataSource.getTasks(page, limit);

        // Cache Data Logic
        final tasksToCache = remoteTasks.map((task) {
          return TasksCompanion(
            serverId: drift.Value(task.id),
            title: drift.Value(task.title),
            description: drift.Value(task.description ?? ""),
            status: drift.Value(task.status),
            isSynced: const drift.Value(true),
            startTaskAt: drift.Value(task.startTaskAt), // Use value from model
            // endTaskAt: drift.Value(task.endTaskAt), // Uncomment if model has this
          );
        }).toList();

        await localDataSource.cacheTasks(tasksToCache);
        return Right(remoteTasks);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } 
    // 2. Offline -> Fetch Local
    else {
      try {
        final localTasks = await localDataSource.getAllTasks();

        final tasks = localTasks.map((t) => TaskModel(
          id: t.serverId ?? t.id.toString(),
          title: t.title,
          description: t.description,
          status: t.status,
          startTaskAt: t.startTaskAt,
        )).toList();

        return Right(tasks);
      } catch (e) {
        return Left(CacheFailure("No local data found"));
      }
    }
  }

  // UPDATE STATUS

  
  Future<Either<Failure, void>> updateTaskStatus(String taskId, int action) async {
    try {
      String newStatus = 'pending';
      if (action == 1) newStatus = 'processing';
      if (action == 2) newStatus = 'completed';
      if (action == 3 || action == 4) newStatus = 'canceled';

      // 1. Optimistic Update (Local)
      await localDataSource.updateLocalTaskStatus(taskId, newStatus);

      // 2. API Update
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.updateTaskStatus(taskId, action);
        } catch (e) {
          debugPrint("API Update Failed: $e");
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Status Update Failed"));
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
}