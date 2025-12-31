import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/routes.dart';
import '../../../../core/utils/app_constants.dart';

class SplashController extends GetxController {
  final storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  void _checkAuth() async {

    await Future.delayed(const Duration(seconds: 1));

    String? token = await storage.read(key: AppConstants.token);
    
    if (token != null && token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}