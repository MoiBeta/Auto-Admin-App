import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';

class GetAuthState {
  final AuthRepository repository;
  GetAuthState(this.repository);

  Future<AuthCredential?> call() async {
    return await repository.getAuthState();
  }
}
