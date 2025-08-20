import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';

class AuthLogin {
  final AuthRepository repository;
  AuthLogin(this.repository);

  Future<AuthCredential?> call(LoginData loginData) async {
    return await repository.login(loginData);
  }
}
