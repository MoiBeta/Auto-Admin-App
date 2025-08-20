import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';

class ChangePassword {
  final AuthRepository repository;
  ChangePassword(this.repository);

  Future<bool> call(ChangePasswordData changePasswordData) async {
    return await repository.changePassword(changePasswordData);
  }
}
