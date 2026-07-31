import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:auto_admin_app/core/errors/global_error_notifier.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utility class that extracts [AppError] from any exception and reports it
/// to the global error notifier.
class ErrorHandler {
  final Ref _ref;

  ErrorHandler(this._ref);

  /// Extracts an [AppError] from [error] and pushes it to the global notifier.
  void handle(Object error, [StackTrace? stackTrace]) {
    final appError = extractAppError(error);
    _ref.read(globalErrorProvider.notifier).reportError(appError);
  }

  /// Extracts a typed [AppError] from any exception.
  static AppError extractAppError(Object error) {
    if (error is AppException) {
      return error.error;
    }

    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).error;
    }

    if (error is DioException) {
      return AppError(
        message: error.message ?? 'Error de red inesperado.',
        type: AppErrorType.network,
        originalError: error,
      );
    }

    return AppError(
      message: 'Ocurrió un error inesperado.',
      type: AppErrorType.unknown,
      originalError: error,
    );
  }
}

final errorHandlerProvider = Provider<ErrorHandler>(
  (ref) => ErrorHandler(ref),
);
