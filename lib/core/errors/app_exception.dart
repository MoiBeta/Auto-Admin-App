import 'app_error.dart';

/// Exception wrapper that carries a typed [AppError].
/// Thrown by the error interceptor so it can be caught and displayed globally.
class AppException implements Exception {
  final AppError error;

  const AppException(this.error);

  @override
  String toString() => error.toString();
}
