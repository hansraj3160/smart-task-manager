import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_task_manager/features/home/presentation/pages/home_tab.dart';
import 'package:smart_task_manager/features/profile/presentation/pages/profile_screen.dart';
import 'package:smart_task_manager/features/tasks/presentation/pages/task_list_screen.dart';
import '../../../tasks/presentation/pages/add_task_screen.dart';
import '../controllers/dashboard_controller.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
     
      body: Obx(() => IndexedStack(
        index: controller.tabIndex.value,
        children: [
          const HomeTab(),          
         const TaskListScreen(),
          const Center(child: Text("Inbox Screen")), // 2: Inbox
          const   ProfileScreen(), // 3: Profile
        ],
      )),

     
     floatingActionButton: Obx(
  () => AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child: controller.tabIndex.value == 0
        ? Material(
            key: const ValueKey("fab_ripple"),
            color: Colors.transparent,
            shape: const StadiumBorder(),
            elevation: 10,
            shadowColor:
                Get.theme.colorScheme.primary.withOpacity(0.35),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              splashColor:
                  Get.theme.colorScheme.primary.withOpacity(0.35),
              highlightColor:
                  Get.theme.colorScheme.primary.withOpacity(0.15),
              onTap: () {
               Get.to(() => const AddTaskScreen());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Get.theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Add Task",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink(),
  ),
),

      
      bottomNavigationBar: Obx(() => NavigationBar(
        selectedIndex: controller.tabIndex.value,
        onDestinationSelected: controller.changeTabIndex,
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Get.theme.primaryColor.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      )),
    );
  }
}