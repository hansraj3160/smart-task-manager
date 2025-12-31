// Import model
import 'package:smart_task_manager/core/utils/app_constants.dart';
import 'package:smart_task_manager/features/tasks/data/models/task_model.dart';

import '../../../../core/network/api_client.dart';
import '../../../home/data/models/task_summary_model.dart';


abstract class TaskRemoteDataSource {

  Future<TaskSummaryModel> getTaskSummary();
  Future<List<TaskModel>> getTasks(int page, int limit);
  Future<void> createTask(Map<String, dynamic> taskData);
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
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await apiClient.postData(
        AppConstants.tasksUri, 
        taskData,  
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // Success
      } else {
        throw Exception(response.statusText);
      }
    } catch (e) {
      rethrow;
    }
  }
}