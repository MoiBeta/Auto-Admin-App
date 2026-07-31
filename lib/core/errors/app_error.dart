/// Represents a typed application error that can be displayed to the user.
class AppError {
  final String message;
  final AppErrorType type;
  final int? statusCode;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppError($type): $message';
}

enum AppErrorType {
  /// No internet or server unreachable
  network,

  /// Request timed out
  timeout,

  /// 401 - session expired after refresh attempt
  unauthorized,

  /// 403 - forbidden
  forbidden,

  /// 404 - resource not found
  notFound,

  /// 400 - bad request / validation
  validation,

  /// 409 - conflict
  conflict,

  /// 500+ - server error
  server,

  /// Unexpected / unclassified error
  unknown,
}
