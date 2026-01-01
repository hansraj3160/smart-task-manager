import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_task_manager/core/widgets/custom_snackbar.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../domain/repositories/task_repository.dart';
import '../../presentation/controllers/task_controller.dart';

class AddTaskController extends GetxController {
  final TaskRepository repository = Get.find();
  final _storage = const FlutterSecureStorage();

  // Text Controllers
  final titleController = TextEditingController();
  final descController = TextEditingController();
  
  // Reactive Variables
  var startDate = Rxn<DateTime>();
  var startTime = Rxn<TimeOfDay>();
  var endDate = Rxn<DateTime>();
  var endTime = Rxn<TimeOfDay>();
  
  var isLoading = false.obs;

  // --- Date/Time Pickers (Same as before) ---
  Future<void> pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (isStart) startDate.value = picked; else endDate.value = picked;
    }
  }

  Future<void> pickTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (isStart) startTime.value = picked; else endTime.value = picked;
    }
  }

  // --MAIN LOGIC ---
  Future<void> createTask() async {
    // 1️⃣ Validation Logic
    if (titleController.text.trim().isEmpty) {
      _showError("Title is required", "Please enter a task title.");
      return;
    }

    if (startDate.value == null || startTime.value == null) {
      _showError("Start Schedule Missing", "Please select start date and time.");
      return;
    }

    if (endDate.value == null || endTime.value == null) {
      _showError("End Schedule Missing", "Please select end date and time.");
      return;
    }

   
    final startDateTime = DateTime(
      startDate.value!.year, startDate.value!.month, startDate.value!.day,
      startTime.value!.hour, startTime.value!.minute
    );
    final endDateTime = DateTime(
      endDate.value!.year, endDate.value!.month, endDate.value!.day,
      endTime.value!.hour, endTime.value!.minute
    );

    if (endDateTime.isBefore(startDateTime)) {
      _showError("Invalid Schedule", "End time cannot be before start time.");
      return;
    }

    // 2️⃣ API Call
    isLoading.value = true;
    try {
      String? userIdStr = await _storage.read(key: 'user_id'); 
      int userId = userIdStr != null ? int.parse(userIdStr) : 19; 

      final body = {
        "userId": userId,
        "title": titleController.text.trim(),
        "description": descController.text.trim(),
        "startDate": DateFormat('yyyy-MM-dd').format(startDate.value!),
        "startTime": "${startTime.value!.hour.toString().padLeft(2,'0')}:${startTime.value!.minute.toString().padLeft(2,'0')}",
        "endDate": DateFormat('yyyy-MM-dd').format(endDate.value!),
        "endTime": "${endTime.value!.hour.toString().padLeft(2,'0')}:${endTime.value!.minute.toString().padLeft(2,'0')}",
      };

      final result = await repository.createTask(body);

      result.fold(
        (failure) => _showError("Creation Failed", failure.message),
        (success) {
           
         
          showSnack(message:  "Task created successfully!", type: SnackType.success);
          _clearForm(); // Form Clear

          if (Get.isRegistered<TaskController>()) {
             Get.find<TaskController>().refreshTasks();
          }
          if (Get.isRegistered<HomeController>()) {
             Get.find<HomeController>().fetchSummary();
          }

          // Close Screen
          Future.delayed(const Duration(seconds: 1), () {
             Get.back(); 
          });
 
         
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper: Clear Form
  void _clearForm() {
    titleController.clear();
    descController.clear();
    startDate.value = null;
    startTime.value = null;
    endDate.value = null;
    endTime.value = null;
  }

  // Helper: Show Error Snackbar
  void _showError(String title, String message) {
    showSnack(message:  message, type: SnackType.error);
   
  }
}