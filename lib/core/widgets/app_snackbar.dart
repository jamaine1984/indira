import 'package:flutter/material.dart';

class AppSnackBar {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700, Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700, Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blue.shade700, Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
