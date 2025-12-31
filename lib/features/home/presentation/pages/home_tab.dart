import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_task_manager/features/home/presentation/pages/widget/odometer_text.dart';
import 'package:smart_task_manager/features/home/presentation/pages/widget/stat_card.dart';
import '../controllers/home_controller.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: controller.fetchSummary,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Text(
              "Task Summary",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            /// GRID (ALWAYS VISIBLE)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  Obx(() => StatCard(
                        title: "To Do",
                        count: controller.todo.value,
                        color: Colors.blue,
                        icon: Icons.assignment_outlined,
                        isLoading: controller.isLoading.value,
                      )),
                  Obx(() => StatCard(
                        title: "Pending",
                        count: controller.pending.value,
                        color: Colors.orange,
                        icon: Icons.timer_outlined,
                        isLoading: controller.isLoading.value,
                      )),
                  Obx(() => StatCard(
                        title: "Completed",
                        count: controller.completed.value,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                        isLoading: controller.isLoading.value,
                      )),
                  Obx(() => StatCard(
                        title: "Canceled",
                        count: controller.canceled.value,
                        color: Colors.red,
                        icon: Icons.cancel_outlined,
                        isLoading: controller.isLoading.value,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
