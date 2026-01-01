import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

// Aapke project imports (paths check kar lena agar alag hon)
import 'package:smart_task_manager/core/error/failures.dart';
import 'package:smart_task_manager/features/home/presentation/controllers/home_controller.dart';
import 'package:smart_task_manager/features/tasks/domain/repositories/task_repository.dart';
import 'package:smart_task_manager/features/home/data/models/task_summary_model.dart';

// 1. Mock Repository Class
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late HomeController controller;
  late MockTaskRepository repository;

  setUp(() {
    repository = MockTaskRepository();
    Get.reset(); // Purane controllers clear karein
    Get.put<TaskRepository>(repository); // Mock inject karein
    controller = HomeController(); // Controller init karein
  });

  // TEST 1: Success Scenario
  test('fetchSummary updates counts on success', () async {
    // Arrange
    final summary = TaskSummaryModel(
      processing: 1,
      pending: 2,
      completed: 3,
      canceled: 0,
    );
    when(() => repository.getTaskSummary())
        .thenAnswer((_) async => Right(summary));

    // Act
    await controller.fetchSummary(); 

    // Assert
    expect(controller.processing.value, 1);
    expect(controller.pending.value, 2);
    expect(controller.completed.value, 3);
    expect(controller.canceled.value, 0);
    expect(controller.isLoading.value, false);
  });

  // TEST 2: Error Scenario
  test('fetchSummary sets error state on failure', () async {
    // Arrange
    when(() => repository.getTaskSummary())
        .thenAnswer((_) async => Left(ServerFailure('Failed')));

    // Act
    await controller.fetchSummary();

    // Assert
    expect(controller.processing.value, 0); // Should remain 0
    expect(controller.isLoading.value, false);
  });

  // TEST 3: Loading State
  test('isLoading is true while fetching and false after', () async {
    final summary = TaskSummaryModel(
      processing: 2, pending: 3, completed: 4, canceled: 1,
    );

    when(() => repository.getTaskSummary()).thenAnswer((_) async {
       // Jab function chal raha ho, tab loading true honi chahiye
       expect(controller.isLoading.value, true); 
       return Right(summary);
    });

    await controller.fetchSummary();

    expect(controller.isLoading.value, false);
  });

  // TEST 4: OnInit Integration (The one you asked for)
  test('onInit calls fetchSummary', () async {
    // Arrange
    final summary = TaskSummaryModel(
      processing: 5,
      pending: 6,
      completed: 7,
      canceled: 8,
    );

    when(() => repository.getTaskSummary())
        .thenAnswer((_) async => Right(summary));

    final ctrl = HomeController();
    
    // ✅ Act: Manually call onInit() 
    // (Kyunki test environment mein Get.put ke bina constructor onInit call nahi karta)
    ctrl.onInit(); 

    // Wait for async operation to finish
    await Future.delayed(const Duration(milliseconds: 50)); 

    // Assert
    expect(ctrl.processing.value, 5);
    expect(ctrl.pending.value, 6);
    expect(ctrl.completed.value, 7);
    expect(ctrl.canceled.value, 8);
  });
}