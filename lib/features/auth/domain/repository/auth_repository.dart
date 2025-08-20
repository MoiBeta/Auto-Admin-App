import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

abstract class AuthRepository {
  Future<AuthCredential?> getAuthState();
  
  Future<String?> getAccessToken();

  Future<AuthCredential?> login(LoginData loginData);

  Future<AuthCredential?> registerUser(SignUpData signUpData);

  Future<bool> confirmEmail();

  Future<void> resendConfirmationCode();

  Future<void> logout();

  Future<bool> changePassword(ChangePasswordData changePasswordData);
}
