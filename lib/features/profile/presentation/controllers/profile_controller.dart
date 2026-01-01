import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_task_manager/features/tasks/data/datasources/task_local_ds.dart';
import 'package:smart_task_manager/features/tasks/presentation/controllers/task_controller.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../config/routes.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';

class ProfileController extends GetxController {
  final _storage = const FlutterSecureStorage();
  
  var name = ''.obs;
  var email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  void loadProfile() async {
    name.value = await _storage.read(key: AppConstants.userName) ?? 'User';
   email.value = await _storage.read(key: 'user_email') ?? 'user@example.com'; 
  }

  void logout() async {
    final localDS = Get.find<TaskLocalDataSource>();
      await localDS.clearAllData();
    await _storage.deleteAll(); 
    Get.delete<TaskController>(force: true);
      Get.delete<HomeController>(force: true);
      Get.delete<DashboardController>(force: true);
    Get.offAllNamed(AppRoutes.login);  
  }
}