import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class ConfirmEmail {
  final AuthRepository repository;

  ConfirmEmail(this.repository);

  Future<bool> call() {
    return repository.confirmEmail();
  }
}
