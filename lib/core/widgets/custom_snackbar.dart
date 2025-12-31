

import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showSnack({required String message, SnackType type = SnackType.success}) {
  Color bgColor;
  IconData icon;

  switch (type) {
    case SnackType.error:
      bgColor = Colors.redAccent.shade700;
      icon = Icons.error_outline;
      break;
    case SnackType.warning:
      bgColor = Colors.orange.shade700;
      icon = Icons.remove_shopping_cart_outlined;
      break;
    default:
      bgColor = Colors.green.shade700;
      icon = Icons.check_circle;
  }

  Get.rawSnackbar(
    messageText: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: bgColor,
    margin: const EdgeInsets.all(16),
    borderRadius: 14,
    duration: const Duration(seconds: 1),
  );
}

enum SnackType { success, error, warning }
