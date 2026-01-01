import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:smart_task_manager/features/tasks/data/datasources/task_remote_ds.dart';
import 'package:smart_task_manager/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:smart_task_manager/features/tasks/domain/repositories/task_repository.dart';

import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/utils/app_constants.dart';
import 'features/tasks/data/datasources/task_local_ds.dart';

Future<void> init() async {
  // 1. External Dependencies
 Get.lazyPut(() => const FlutterSecureStorage(), fenix: true);
  Get.lazyPut(() => InternetConnectionChecker.instance, fenix: true);

  // 2. Core Features
  Get.lazyPut<NetworkInfo>(
    () => NetworkInfoImpl(Get.find()), 
    fenix: true
  );
  
  Get.lazyPut(
    () => ApiClient(appBaseUrl: AppConstants.baseUrl), 
    fenix: true
  );
  

  // 3. Database (Drift)
 final database = AppDatabase();
  Get.put<AppDatabase>(database, permanent: true);
  //Register TaskLocalDataSource
  Get.lazyPut<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(Get.find()),  
    fenix: true
  );
  // Remote API Source
  Get.lazyPut<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(Get.find()),
    fenix: true
  );
  Get.lazyPut<TaskRepository>(
  () => TaskRepositoryImpl(
    localDataSource: Get.find(),
    remoteDataSource: Get.find(), 
    networkInfo: Get.find(),
  ),
  fenix: true,
);
}