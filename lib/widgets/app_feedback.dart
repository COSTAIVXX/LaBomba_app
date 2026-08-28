import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppFeedbackType { success, warning, error }

class AppFeedback {
  const AppFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.success);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.warning);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppFeedbackType.error);
  }

  static void _show(
    BuildContext context,
    String message,
    AppFeedbackType type,
  ) {
    final scheme = Theme.of(context).colorScheme;
    late final IconData icon;
    late final Color color;
    switch (type) {
      case AppFeedbackType.success:
        icon = Icons.check_circle_outline;
        color = AppTheme.primary;
        break;
      case AppFeedbackType.warning:
        icon = Icons.warning_amber_outlined;
        color = AppTheme.accent;
        break;
      case AppFeedbackType.error:
        icon = Icons.error_outline;
        color = scheme.error;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.7)),
          ),
          backgroundColor: scheme.surfaceContainerHighest,
          elevation: 8,
        ),
      );
  }
}
