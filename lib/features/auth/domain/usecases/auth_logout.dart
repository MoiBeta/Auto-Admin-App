import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class AuthLogout {
  final AuthRepository repository;
  AuthLogout(this.repository);

  Future<void> call() async {
    return await repository.logout();
  }
}
