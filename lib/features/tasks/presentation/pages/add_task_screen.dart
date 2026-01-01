import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smart_task_manager/core/utils/app_sizes.dart';

import '../controllers/add_task_controller.dart';


class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddTaskController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Task"),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => _unfocus(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ///  TITLE
              TextField(
                controller: controller.titleController,
                textInputAction: TextInputAction.next,
                decoration:  InputDecoration(
                  labelText: "Task Title",
                  labelStyle: TextStyle(color:!controller.titleController.text.contains('Task Title')? const Color.fromARGB(255, 120, 120, 120): Theme.of(context).colorScheme.primary),
                  prefixIcon: Icon(Icons.title, color: Theme.of(context).colorScheme.primary),
                ),
              ),

              const SizedBox(height: AppSizes.md),

              ///  DESCRIPTION
              TextField(
                controller: controller.descController,
                maxLines: 3,
                decoration:  InputDecoration(
                  labelText: "Description",
                  labelStyle: TextStyle(color:!controller.descController.text.contains('Description')? const Color.fromARGB(255, 120, 120, 120): Theme.of(context).colorScheme.primary),
                  prefixIcon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary  ),
                ),

              ),

              const SizedBox(height: AppSizes.xl),

              /// START
              _SectionTitle(title: "Start Schedule"),
              const SizedBox(height: AppSizes.sm),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _PickerField(
                        label: controller.startDate.value == null
                            ? "Start Date"
                            : DateFormat('dd MMM yyyy')
                                .format(controller.startDate.value!),
                        icon: Icons.calendar_today,
                        onTap: () {
                        FocusScope.of(context).unfocus();
                          controller.pickDate(context, true);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Obx(
                      () => _PickerField(
                        label: controller.startTime.value == null
                            ? "Start Time"
                            : controller.startTime.value!.format(context),
                        icon: Icons.access_time,
                        onTap: () {
                          _unfocus(context);
                          controller.pickTime(context, true);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.lg),

              /// END
              _SectionTitle(title: "End Schedule"),
              const SizedBox(height: AppSizes.sm),

              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _PickerField(
                        label: controller.endDate.value == null
                            ? "End Date"
                            : DateFormat('dd MMM yyyy')
                                .format(controller.endDate.value!),
                        icon: Icons.event,
                        onTap: () {
                          _unfocus(context);
                          controller.pickDate(context, false);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Obx(
                      () => _PickerField(
                        label: controller.endTime.value == null
                            ? "End Time"
                            : controller.endTime.value!.format(context),
                        icon: Icons.access_time_filled,
                        onTap: () {
                          _unfocus(context);
                          controller.pickTime(context, false);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.xl * 2),

              /// CREATE BUTTON
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () {
                            _unfocus(context);
                            controller.createTask();
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Create Task",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keyboard + Focus clear helper
  void _unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/*                               SECTION TITLE                                */

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}


/*                              PICKER FIELD                                  */


class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon,color: Theme.of(context).colorScheme.primary,),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ).copyWith(
            color: label.contains("Date") || label.contains("Time") || label.contains("Task") || label.contains("Description")
                ?const Color.fromARGB(255, 120, 120, 120)
                :const Color.fromARGB(255, 100, 100, 100),
          ),
        ),
      ),
    );
  }
}
