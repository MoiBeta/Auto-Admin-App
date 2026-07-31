import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global error state that can be pushed from anywhere in the app.
/// Listeners (like the ErrorListener widget) react to changes and display
/// notifications to the user.
class GlobalErrorNotifier extends StateNotifier<AppError?> {
  GlobalErrorNotifier() : super(null);

  /// Push an error to be displayed globally.
  void reportError(AppError error) {
    state = error;
    // Reset to null so the same error can be reported again if needed.
    state = null;
  }
}

final globalErrorProvider =
    StateNotifierProvider<GlobalErrorNotifier, AppError?>(
  (_) => GlobalErrorNotifier(),
);
