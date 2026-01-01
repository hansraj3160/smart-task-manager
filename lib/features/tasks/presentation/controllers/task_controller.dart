import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:smart_task_manager/core/widgets/custom_snackbar.dart';
import 'package:smart_task_manager/features/home/presentation/controllers/home_controller.dart';
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
  Timer? _debounceTimer;
  @override
  void onInit() {
    super.onInit();
    fetchInitialTasks();
  
    InternetConnectionChecker.instance.onStatusChange.listen((status) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (status == InternetConnectionStatus.connected) {
        debugPrint(" Internet Restored: Auto Refreshing Tasks...");
       _performSync();
      }
      });});
  
  
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent &&
          !isMoreLoading.value &&
          hasMore.value) {
        loadMore();
      }
    });
  }
  Future<void> _performSync() async {
    await repository.syncPendingTasks();
    refreshTasks();
   Get.find<HomeController>().fetchSummary();
  }


Future<void> deleteTask(TaskModel task) async {

  final index = _allTasks.indexWhere((t) => t.id == task.id);
  if (index != -1) {
    _allTasks.removeAt(index);
    change(_allTasks, status: RxStatus.success()); 
  }

  final result = await repository.deleteTask(task.id);
  
  result.fold(
    (failure) {
      showSnack(message: "Task marked for deletion", type: SnackType.warning);
    },
    (success) {
        // refreshTasks();
   Get.find<HomeController>().fetchSummary();
      showSnack(message: "Task deleted successfully", type: SnackType.success);
    },
  );
}
  Future<void> fetchInitialTasks() async {
    page = 1;
    hasMore.value = true;
    _allTasks.clear();
    change(null, status: RxStatus.loading()); // Full screen loader
    await _getData();
  }
  Future<void> loadMore() async {
    if (isMoreLoading.value || !hasMore.value) return;

    isMoreLoading.value = true;
    page++; 
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
          showSnack(
            message: "Could not load more tasks",
            type: SnackType.error,
          );
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
Future<void> changeTaskStatus(TaskModel task, int action) async {
    Get.back(); // Close Bottom Sheet


    final repoImpl = repository as dynamic; 
    await repoImpl.updateTaskStatus(task.id, action);

    // Refresh List to show new color
    _performSync() ;
    
    showSnack(message:"Task status updated successfully",type: SnackType.success);
    
  }
  void showStatusBottomSheet(TaskModel task) {
  // final isDark = Get.theme.brightness == Brightness.dark;

  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Text(
            "Update Status",
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Get.theme.hintColor,
            ),
          ),

          const SizedBox(height: 24),

          /// ACTIONS
          if (task.status.toLowerCase() == 'pending' ||
              task.status.toLowerCase() == 'to_do') ...[
            Row(
              children: [
                Expanded(
                  child: _statusActionButton(
                    label: "Start",
                    icon: Icons.play_arrow,
                    color: Get.theme.colorScheme.primary,
                    onTap: () => changeTaskStatus(task, 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statusActionButton(
                    label: "Cancel",
                    icon: Icons.close,
                    color: Get.theme.colorScheme.error,
                    onTap: () => changeTaskStatus(task, 4),
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ] else if (task.status.toLowerCase() == 'processing') ...[
            Row(
              children: [
                Expanded(
                  child: _statusActionButton(
                    label: "Complete",
                    icon: Icons.check,
                    color: Colors.green,
                    onTap: () => changeTaskStatus(task, 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statusActionButton(
                    label: "Cancel",
                    icon: Icons.close,
                    color: Get.theme.colorScheme.error,
                    onTap: () => changeTaskStatus(task, 3),
                    isOutlined: true,
                  ),
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Text(
                "No actions available",
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.hintColor,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
Widget _statusActionButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
  bool isOutlined = false,
}) {
  return SizedBox(
    height: 48,
    child: isOutlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
  );
}

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
