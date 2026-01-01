import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_task_manager/core/utils/app_colors.dart';
import 'package:smart_task_manager/features/tasks/presentation/pages/add_task_screen.dart';

import '../controllers/task_controller.dart';
import '../../data/models/task_model.dart';
import 'package:shimmer/shimmer.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TaskController());

    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text("My Tasks"),
          centerTitle: true,
          elevation: 0,
          systemOverlayStyle: controller.isOffline.value
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.red, // Offline Color
                  statusBarIconBrightness: Brightness.light,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent, // Online (Default) Color
                ),
        ),
        body: RefreshIndicator(
          onRefresh: controller.refreshTasks,
          child: controller.obx(
            (tasks) => Obx(
              () => ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    tasks!.length + (controller.isMoreLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == tasks.length) {
                    return const _PaginationLoader();
                  }

                  return Dismissible(
                    key: Key(tasks[index].id),
                    direction: DismissDirection.endToStart,

                    background: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    onDismissed: (direction) {
                      controller.deleteTask(tasks[index]);
                    },
                    child: GestureDetector(
                      onTap: () =>
                          controller.showStatusBottomSheet(tasks[index]),
                      child: _AnimatedTaskCard(
                        task: tasks[index],
                        index: index,
                      ),
                    ),
                  );
                },
              ),
            ),
            onLoading:  _TaskListShimmer(),
            onEmpty: const Center(child: Text("No tasks found")),
            onError: (e) => Center(child: Text("Error: $e")),
          ),
        ),
        
     floatingActionButton: AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child:  Material(
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
          
         
  ),
),

     
      ),
    );
  }
}

class _TaskListShimmer extends StatelessWidget {
  const _TaskListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => const _TaskCardShimmer(),
    );
  }
}

class _TaskCardShimmer extends StatelessWidget {
  const _TaskCardShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              /// Description
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(height: 12),

              /// Date row
              Container(
                height: 10,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//!/*                               ANIMATED CARD                                */

class _AnimatedTaskCard extends StatelessWidget {
  final TaskModel task;
  final int index;

  const _AnimatedTaskCard({required this.task, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _TaskCard(task: task),
    );
  }
}

//!/*                                  TASK CARD                                 */

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,

        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(isDark ? 0.12 : 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: statusColor.withOpacity(isDark ? 0.35 : 0.25),
        ),

        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withOpacity(0.9),
                child: Icon(
                  _getStatusIcon(task.status),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(label: task.status, color: statusColor),
            ],
          ),

          const SizedBox(height: 8),

          /// DESCRIPTION
          if (task.description != null && task.description!.isNotEmpty)
            Text(
              task.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),

          const SizedBox(height: 7),

          /// DATE
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 2),
              Text(
                task.startTaskAt != null
                    ? DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(task.startTaskAt!)
                    : "No Date",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Spacer(),
              Icon(
                Icons.calendar_today,
                size: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 2),
              Text(
                task.startTaskAt != null
                    ? DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(task.startTaskAt!)
                    : "No Date",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*                                STATUS CHIP                                 */
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/*                             HELPERS / UTILITIES                             */

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'pending':
      return Colors.orange;
    case 'canceled':
      return Colors.red;
    default:
      return Colors.blue;
  }
}

IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Icons.check;
    case 'pending':
      return Icons.access_time;
    case 'canceled':
      return Icons.close;
    default:
      return Icons.assignment_outlined;
  }
}

class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Loading more…",
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
