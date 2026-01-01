// Import model
import 'package:flutter/material.dart';
import 'package:smart_task_manager/core/utils/app_constants.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';

import '../../../../core/network/api_client.dart';
import '../../../home/data/models/task_summary_model.dart';


abstract class TaskRemoteDataSource {

  Future<TaskSummaryModel> getTaskSummary();
  Future<List<TaskModel>> getTasks(int page, int limit);
  // Future<void> createTask(Map<String, dynamic> taskData);
  Future<String> createTask(Map<String, dynamic> taskData);
  Future<void> updateTaskStatus(String taskId, int action);
  Future<void> deleteTask(String id);

}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient apiClient;
  TaskRemoteDataSourceImpl(this.apiClient);
  @override
  Future<TaskSummaryModel> getTaskSummary() async {
    try {
      final response = await apiClient.getData(AppConstants.taskSummaryUri);
      
      if (response.statusCode == 200) {
        return TaskSummaryModel.fromJson(response.body);
      } else {
        throw Exception(response.statusText);
      }
    } catch (e) {
      rethrow;
    }
  }
  @override
Future<void> deleteTask(String id) async {
  // ApiClient call karein
  await apiClient.deleteData('/tasks/$id');
}
  @override
  Future<List<TaskModel>> getTasks(int page, int limit) async {
    try {
      final response = await apiClient.getData(
        AppConstants.tasksUri,
        query: {
          'page': page, 
          'limit': limit
        },
      );

      if (response.statusCode == 200) {
        
        final List<dynamic> data = response.body['data'];  
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception(response.statusText);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await apiClient.postData(
        AppConstants.tasksUri, 
        taskData,  
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Task created: ${response.body['task']['id']}");
      return response.body['task']['id'];
      } else {
        throw Exception(response.statusText);
      }
    } catch (e) {
      rethrow;
    }
  }
  @override
  Future<void> updateTaskStatus(String taskId, int action) async {
    try {
      // URL: /tasks/:id/status/:action
      final url = "${AppConstants.tasksUri}/$taskId/status/$action";
      
      final response = await apiClient.patchData(url, {}); // Body empty hai

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(response.statusText);
      }
    } catch (e) {
      rethrow;
    }
  }
}