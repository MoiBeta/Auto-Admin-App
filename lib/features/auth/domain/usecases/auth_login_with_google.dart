import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class AuthLoginWithGoogle {
  final AuthRepository repository;
  AuthLoginWithGoogle(this.repository);

  /// Null when the user cancels.
  Future<AuthCredential?> call() => repository.loginWithGoogle();
}
