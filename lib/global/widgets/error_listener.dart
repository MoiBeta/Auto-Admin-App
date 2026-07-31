import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/global_error_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget that listens to the global error state and shows a SnackBar
/// whenever an error is reported.
///
/// Place this widget high in the tree (e.g., wrapping your router/scaffold).
class ErrorListener extends ConsumerWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppError?>(globalErrorProvider, (previous, next) {
      if (next != null) {
        _showErrorSnackBar(context, next);
      }
    });

    return child;
  }

  void _showErrorSnackBar(BuildContext context, AppError error) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _iconForType(error.type),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _colorForType(error.type),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  IconData _iconForType(AppErrorType type) {
    return switch (type) {
      AppErrorType.network => Icons.wifi_off_rounded,
      AppErrorType.timeout => Icons.timer_off_rounded,
      AppErrorType.unauthorized => Icons.lock_outline_rounded,
      AppErrorType.forbidden => Icons.block_rounded,
      AppErrorType.notFound => Icons.search_off_rounded,
      AppErrorType.validation => Icons.error_outline_rounded,
      AppErrorType.conflict => Icons.warning_amber_rounded,
      AppErrorType.server => Icons.cloud_off_rounded,
      AppErrorType.unknown => Icons.report_problem_rounded,
    };
  }

  Color _colorForType(AppErrorType type) {
    return switch (type) {
      AppErrorType.network || AppErrorType.timeout => const Color(0xFFE65100),
      AppErrorType.unauthorized => const Color(0xFF6A1B9A),
      AppErrorType.server => const Color(0xFFC62828),
      _ => const Color(0xFFD32F2F),
    };
  }
}
