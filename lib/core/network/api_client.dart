 
import 'package:dio/dio.dart' as dio;  
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, MultipartFile; 
import 'package:get/get.dart' as get_pkg show Response; 
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_task_manager/config/routes.dart';
import 'package:smart_task_manager/core/utils/app_constants.dart';

class ApiClient extends GetxService {
  final String appBaseUrl;
  late dio.Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? token;
  
  static const String noInternetMessage = 'Connection to API server failed due to internet connection';

  ApiClient({required this.appBaseUrl}) {
    _initDio();
  }

  void _initDio() async {
    // 1. Initial Setup
    token = await _storage.read(key: AppConstants.token);
    
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: appBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    // 2. Add Interceptor (The Magic Part)
    _dio.interceptors.add(
      dio.QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (dio.DioException error, handler) async {
          // 3. Agar 401 aaya, toh ruk jao
          if (error.response?.statusCode == 401) {
            try {
           // 1. Refresh Token nikalo
              debugPrint('Access token expired. Attempting to refresh token...');
              String? storedRefreshToken = await _storage.read(key: AppConstants.refreshToken);
              
              if (storedRefreshToken == null) {
                return handler.next(error); // Logout if no refresh token
              }

              
              final refreshDio = dio.Dio(dio.BaseOptions(baseUrl: appBaseUrl));
              final refreshResponse = await refreshDio.post(
                AppConstants.refreshTokenUri,
                data: {'refreshToken': storedRefreshToken}, // Aapki API body
              );

              if (refreshResponse.statusCode == 200) {
               
                String newAccessToken = refreshResponse.data['token']; 
               
                String? newRefreshToken = refreshResponse.data['refreshToken'];

                await _storage.write(key: AppConstants.token, value: newAccessToken);
                if (newRefreshToken != null) {
                   await _storage.write(key: AppConstants.refreshToken, value: newRefreshToken);
                }

             
                token = newAccessToken;

                
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final clonedRequest = await _dio.request(
                  opts.path,
                  options: dio.Options(method: opts.method, headers: opts.headers),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(clonedRequest);
              }
            } catch (e) {
              
              await _performLogout();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // --- Helper Methods ---

  Future<void> _performLogout() async {
    await _storage.deleteAll();
    Get.offAllNamed(AppRoutes.login);  
  }

//! // --- Public Methods (Compatible with your Repository) ---

  Future<get_pkg.Response> getData(String uri, {Map<String, dynamic>? query}) async {
    try {
      var response = await _dio.get(uri, queryParameters: query);
      return _formatResponse(response);
    } on dio.DioException catch (e) {
      return _formatError(e);
    }
  }

  Future<get_pkg.Response> postData(String uri, dynamic body) async {
    try {
      if (kDebugMode) {
        debugPrint('[ApiClient] POST $uri');
        debugPrint('[ApiClient] Body: $body');
      }
      var response = await _dio.post(uri, data: body);
      if (kDebugMode) {
        debugPrint('[ApiClient] Response(${response.statusCode}) $uri');
        debugPrint('[ApiClient] Data: ${response.data}');
      }
      return _formatResponse(response);
    } on dio.DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] ERROR POST $uri');
        debugPrint('[ApiClient] Status: ${e.response?.statusCode}');
        debugPrint('[ApiClient] Message: ${e.message}');
        debugPrint('[ApiClient] Error data: ${e.response?.data}');
      }
      return _formatError(e);
    }
  }

  Future<get_pkg.Response> putData(String uri, dynamic body) async {
    try {
      var response = await _dio.put(uri, data: body);
      return _formatResponse(response);
    } on dio.DioException catch (e) {
      return _formatError(e);
    }
  }
Future<get_pkg.Response> patchData(String uri, Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch(uri, data: body);
      return _formatResponse(response);
    } on  dio.DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
  Future<get_pkg.Response> deleteData(String uri) async {
    try {
      var response = await _dio.delete(uri);
      return _formatResponse(response);
    } on dio.DioException catch (e) {
      return _formatError(e);
    }
  }

  get_pkg.Response _formatResponse(dio.Response response) {
    return get_pkg.Response(
      body: response.data,
      bodyString: response.data.toString(),
      headers: response.headers.map.map((key, value) => MapEntry(key, value.join(','))),
      statusCode: response.statusCode,
      statusText: response.statusMessage,
    );
  }

  get_pkg.Response _formatError(dio.DioException e) {
    return get_pkg.Response(
      statusCode: e.response?.statusCode ?? 1,
      statusText: e.response?.statusMessage ?? noInternetMessage,
      body: e.response?.data,
    );
  }
}