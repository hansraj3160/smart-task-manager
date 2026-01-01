import 'package:get/get.dart';
import '../../data/models/task_summary_model.dart';
import '../../../tasks/domain/repositories/task_repository.dart'; 

class HomeController extends GetxController with StateMixin<TaskSummaryModel> {

  final TaskRepository repository = Get.find(); 
final processing = 0.obs;
  final pending = 0.obs;
  final completed = 0.obs;
  final canceled = 0.obs;
   final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummary();
  }

  void fetchSummary() async {
    isLoading.value = true;
    change(null, status: RxStatus.loading());
    
    final result = await repository.getTaskSummary();
    
    result.fold(
      (failure) => change(null, status: RxStatus.error(failure.message)),
      (TaskSummaryModel summary) {
        processing.value = summary.processing;
        pending.value = summary.pending;
        completed.value = summary.completed;
        canceled.value = summary.canceled;
      },
    );
     isLoading.value = false;
  }
}