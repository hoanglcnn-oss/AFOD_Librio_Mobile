import 'package:flutter/material.dart';

enum AppToastType { success, warning, error }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context,
    String message, {
    required AppToastType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (
      Color backgroundColor,
      Color foregroundColor,
      IconData iconData,
    ) = switch (type) {
      AppToastType.success => (
        Colors.green.shade700,
        Colors.white,
        Icons.check_circle_outline,
      ),
      AppToastType.warning => (
        Colors.amber.shade800,
        Colors.white,
        Icons.warning_amber_rounded,
      ),
      AppToastType.error => (
        colorScheme.error,
        colorScheme.onError,
        Icons.error_outline,
      ),
    };

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: foregroundColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppToastType.success, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppToastType.warning, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, type: AppToastType.error, duration: duration);
  }
}
