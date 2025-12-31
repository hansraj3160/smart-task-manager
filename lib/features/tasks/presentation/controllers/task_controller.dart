import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_task_manager/core/widgets/custom_snackbar.dart';
import '../../domain/repositories/task_repository.dart';
import '../../data/models/task_model.dart';

class TaskController extends GetxController with StateMixin<List<TaskModel>> {
  final TaskRepository repository = Get.find();
  final ScrollController scrollController = ScrollController();
  
  var page = 1;
  final int limit = 10;  
  var isMoreLoading = false.obs;
  var hasMore = true.obs;
  final List<TaskModel> _allTasks = [];
@override
  void onInit() {
    super.onInit();
    fetchInitialTasks();
    
 
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent &&
          !isMoreLoading.value &&
          hasMore.value) {
        loadMore();
      }
    });
  }

  // First Time Load
  Future<void> fetchInitialTasks() async {
    page = 1;
    hasMore.value = true;
    _allTasks.clear();
    change(null, status: RxStatus.loading()); // Full screen loader
    await _getData();
  }

  // Load Next Page
  Future<void> loadMore() async {
    if (isMoreLoading.value || !hasMore.value) return;
    
    isMoreLoading.value = true;
    page++; // Next Page
    await _getData();
    isMoreLoading.value = false;
  }

  // Pull to Refresh
  Future<void> refreshTasks() async {
    await fetchInitialTasks();
  }

  // Common Data Fetcher
  Future<void> _getData() async {
    final result = await repository.getTasks(page, limit);

    result.fold(
      (failure) {
        if (page == 1) {
          change(null, status: RxStatus.error(failure.message));
        } else {
          
          showSnack(message:  "Could not load more tasks", type: SnackType.error);
        }
      },
      (newTasks) {
      
        if (newTasks.length < limit) {
          hasMore.value = false; 
        }

        _allTasks.addAll(newTasks);  

        if (_allTasks.isEmpty) {
          change([], status: RxStatus.empty());
        } else {
          change(_allTasks, status: RxStatus.success());
        }
      },
    );
  }
  
  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}