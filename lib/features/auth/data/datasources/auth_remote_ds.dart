import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_constants.dart';
import 'package:get/get.dart' hide FormData;
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient = Get.find();  

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await apiClient.postData(
        AppConstants.loginUri, 
        {
          "email": email,
          "password": password
        }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;  
      } else {
        throw Exception(response.body['message'] ?? "Login Failed");
      }
    } catch (e) {
      throw Exception("Login Failed: ${e.toString()}");
    }
  }
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {

      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'password': password,
      });

      final response = await apiClient.postData(AppConstants.signupUri, formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body; 
      } else {
        throw Exception(response.body['message'] ?? 'Signup failed');
      }
    } catch (e) {
      rethrow;
    }
  }

}