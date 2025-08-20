import 'auth_error.dart';

class AuthException implements Exception {
  final AuthError error;
  final String? message;

  AuthException(this.error, {this.message});

  @override
  String toString() => 'AuthException: $error - $message';
}