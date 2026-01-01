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

  Future<int> _getUserId() async {
    String? userIdStr = await _storage.read(key: 'user_id');
    return userIdStr != null ? int.parse(userIdStr) : 0;
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      await localDataSource.markTaskAsDeleted(taskId);

      if (await networkInfo.isConnected) {
        try {
          // Server Call
          await remoteDataSource.deleteTask(taskId);
        } catch (e) {
          debugPrint(" Offline Delete: Sync will handle it later");
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Delete Failed"));
    }
  }

  @override
  Future<void> syncPendingTasks() async {
    if (await networkInfo.isConnected) {
      try {
        final userId = await _getUserId();
        final pendingTasks = await localDataSource.getUnsyncedTasks(userId);
        if (pendingTasks.isEmpty) return;
        for (var task in pendingTasks) {
          try {
            if (task.isDeleted == true) {
              debugPrint(" Syncing DELETE for: ${task.title}");
              if (task.serverId != null) {
                try {
                  await remoteDataSource.deleteTask(task.serverId!);
                  await localDataSource.deleteTaskPermanently(task.id);
                  debugPrint("Deleted from Server & Local");
                } catch (e) {
                  debugPrint("Delete Sync Failed: $e");
                }
              } else {
                await localDataSource.deleteTaskPermanently(task.id);
                debugPrint("Deleted Local-only task");
              }
            } else if (task.serverId == null) {
              final Map<String, dynamic> taskData = {
                "userId": userId,
                "title": task.title,
                "description": task.description,
                "startDate": task.startTaskAt != null
                    ? DateFormat('yyyy-MM-dd').format(task.startTaskAt!)
                    : null,
                "startTime": task.startTaskAt != null
                    ? DateFormat('HH:mm').format(task.startTaskAt!)
                    : null,
                "endDate": task.endTaskAt != null
                    ? DateFormat('yyyy-MM-dd').format(task.endTaskAt!)
                    : null,
                "endTime": task.endTaskAt != null
                    ? DateFormat('HH:mm').format(task.endTaskAt!)
                    : null,
              };
              debugPrint("Creating New Task on Sync: ${task.title}");
              final serverId = await remoteDataSource.createTask(taskData);
              await localDataSource.updateTaskSyncStatus(task.id, serverId);
             
            } else {
              debugPrint("Updating Existing Task on Sync: ${task.title}");
             bool success = await _syncTaskStatus(task.serverId!, task.status);

            if (success) {
              await localDataSource.updateTaskSyncStatus(
                task.id,
                task.serverId!,
              );
            }
            }
          } catch (e) {
            debugPrint("Failed to sync task '${task.title}': $e");
          }
        }
      } catch (e) {
        debugPrint("Sync Error: $e");
      }
    }
  }

  // Helper Function: Smart Status Update
  Future<bool> _syncTaskStatus(String serverId, String status) async {
    try {
      if (status == 'processing') {
        try {
          await remoteDataSource.updateTaskStatus(serverId, 1);
          return true;
        } catch (_) {
           
        }
      } else if (status == 'completed') {
        try {
        await remoteDataSource.updateTaskStatus(serverId, 1);
        await remoteDataSource.updateTaskStatus(serverId, 2);
        return true;
      } catch (e) {
        debugPrint("Complete status sync failed: $e");
        return false; 
      }
      } else if (status == 'canceled') {
       try {
        await remoteDataSource.updateTaskStatus(serverId, 4);
        return true;
      } catch (e) {
        try {
          await remoteDataSource.updateTaskStatus(serverId, 3);
          return true;
        } catch (e2) {
           return false; // Failed both attempts
        }
      }
      }
      return true;
    } catch (e) {
      debugPrint("Status Sync Error: $e");
      return false;
    }
  }

  //  CREATE TASK

  @override
  Future<Either<Failure, void>> createTask(
    Map<String, dynamic> taskData,
  ) async {
    try {
      // Parse Dates for Local DB
      final userId = await _getUserId();
      DateTime? startAt;
      if (taskData['startDate'] != null && taskData['startTime'] != null) {
        try {
          startAt = DateTime.parse(
            "${taskData['startDate']} ${taskData['startTime']}",
          );
        } catch (_) {}
      }
      DateTime? endAt;
      if (taskData['endDate'] != null && taskData['endTime'] != null) {
        try {
          endAt = DateTime.parse(
            "${taskData['endDate']} ${taskData['endTime']}",
          );
        } catch (_) {}
      }

      // 1. Save to Local DB (Offline First)
      final localId = await localDataSource.insertTask(
        TasksCompanion(
          userId: drift.Value(userId),
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

  @override
  Future<Either<Failure, List<TaskModel>>> getTasks(int page, int limit) async {
    final userId = await _getUserId();

    if (await networkInfo.isConnected) {
      try {
        final remoteTasks = await remoteDataSource.getTasks(page, limit);

        final tasksToCache = remoteTasks.map((task) {
          return TasksCompanion(
            userId: drift.Value(userId),
            serverId: drift.Value(task.id),
            title: drift.Value(task.title),
            description: drift.Value(task.description ?? ""),
            status: drift.Value(task.status),
            isSynced: const drift.Value(true),
            startTaskAt: drift.Value(task.startTaskAt),
            endTaskAt: drift.Value(task.endTaskAt),
          );
        }).toList();

        await localDataSource.cacheTasks(tasksToCache);
        return Right(remoteTasks);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final localTasks = await localDataSource.getAllTasks(userId);

        final tasks = localTasks
            .map(
              (t) => TaskModel(
                id: t.serverId ?? t.id.toString(),
                title: t.title,
                description: t.description,
                status: t.status,
                startTaskAt: t.startTaskAt,
              ),
            )
            .toList();

        return Right(tasks);
      } catch (e) {
        return Left(CacheFailure("No local data found"));
      }
    }
  }

  // UPDATE STATUS

  Future<Either<Failure, void>> updateTaskStatus(
    String taskId,
    int action,
  ) async {
    try {
      String newStatus = 'pending';
      if (action == 1) newStatus = 'processing';
      if (action == 2) newStatus = 'completed';
      if (action == 3 || action == 4) newStatus = 'canceled';

      // 1. Optimistic Update (Local)
      await localDataSource.updateLocalTaskStatus(
        taskId,
        newStatus,
        isSynced: false,
      );

      // 2. API Update
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.updateTaskStatus(taskId, action);
          await localDataSource.updateLocalTaskStatus(
            taskId,
            newStatus,
            isSynced: true,
          );

          debugPrint("Task status updated on server & marked synced.");
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
