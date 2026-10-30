import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Informational messages that can be pushed from anywhere in the app, shown
/// by the ErrorListener widget.
class GlobalMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) {
    state = message;
    // Reset to null so the same message can be shown again.
    state = null;
  }
}

final globalMessageProvider = NotifierProvider<GlobalMessageNotifier, String?>(
  GlobalMessageNotifier.new,
);
