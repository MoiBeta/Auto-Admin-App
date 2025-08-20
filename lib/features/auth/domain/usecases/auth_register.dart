import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

class AuthRegister {
  final AuthRepository repository;

  AuthRegister(this.repository);

  Future<AuthCredential?> call(SignUpData signUpData) {
    return repository.registerUser(signUpData);
  }
}
