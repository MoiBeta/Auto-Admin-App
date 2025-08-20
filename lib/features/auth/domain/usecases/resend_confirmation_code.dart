import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class ResendConfirmationCode {
  final AuthRepository repository;

  ResendConfirmationCode(this.repository);

  Future<void> call() async {
    return repository.resendConfirmationCode();
  }
}
