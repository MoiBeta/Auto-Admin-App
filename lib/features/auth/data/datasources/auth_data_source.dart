import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

abstract class AuthDataSource {
  Future<bool> changePassword(ChangePasswordData changePasswordData);
  Future<bool> confirmEmail();
  Future<AuthCredentialModel?> getAuthState();
  Future<AuthCredentialModel?> login(LoginData loginData);
  Future<AuthCredentialModel?> loginWithGoogle(String idToken);
  Future<void> logout();
  Future<AuthCredentialModel?> registerUser(SignUpData signUpData);
  Future<void> resendConfirmationCode();
}
