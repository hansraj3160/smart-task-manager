import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../config/routes.dart';

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
    await _storage.deleteAll(); 
    Get.offAllNamed(AppRoutes.login);  
  }
}