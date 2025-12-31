import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:smart_task_manager/features/auth/data/datasources/auth_remote_ds.dart';
import '../../../../config/routes.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class AuthController extends GetxController {
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource(); 
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController(text: 'rajh8157@gmail.com');
  final passwordController = TextEditingController(text: 'password123');
  

  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {

    if (!loginFormKey.currentState!.validate()) {
      return; 
    }

    isLoading.value = true;
    try {
      final data = await _authDataSource.login(
        emailController.text.trim(), 
        passwordController.text.trim()
      );
   
      String accessToken = data['token'];
      String refreshToken = data['refreshToken'];
      var user = data['user'];

      await _storage.write(key: AppConstants.token, value: accessToken);
      await _storage.write(key: AppConstants.refreshToken, value: refreshToken);
      await _storage.write(key: AppConstants.userName, value: user['name']);
      await _storage.write(key: 'user_email', value: user['email']);
     Get.offAllNamed(AppRoutes.dashboard);
      
      showSnack(message:  "Login successful", type: SnackType.success);
       } 
          catch (e) {
      debugPrint("Login Error: $e");
      showSnack(message: "Login failed: ${e.toString()}", type: SnackType.error);
    } finally {
      isLoading.value = false;
    }
  }

  // --- Signup Logic ---
 Future<void> signup() async {
    // 1. Validation
    if (!signupFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      // 2. Call API
      final data = await _authDataSource.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      String accessToken = data['token'];
      String refreshToken = data['refreshToken'];
      var user = data['user'];

      await _storage.write(key: AppConstants.token, value: accessToken);
      await _storage.write(key: AppConstants.refreshToken, value: refreshToken);
      await _storage.write(key: AppConstants.userName, value: user['name']);
      await _storage.write(key: 'user_email', value: user['email']);

     Get.offAllNamed(AppRoutes.dashboard);
      showSnack(
        message: "Account created successfully", 
        type: SnackType.success
      );  
    
    } catch (e) {
      debugPrint("Signup Error: $e");
    
      showSnack(message:  "Signup failed: ${e.toString()}", type: SnackType.error);
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}