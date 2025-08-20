import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

class AuthRepositoryImpl extends AuthRepository{
  final AuthDataSource authDataSource;
  AuthRepositoryImpl(this.authDataSource);

  @override
  Future<bool> changePassword(ChangePasswordData changePasswordData) async {
    return authDataSource.changePassword(changePasswordData);
  }

  @override
  Future<bool> confirmEmail() async {
    return authDataSource.confirmEmail();
  }

  @override
  Future<String?> getAccessToken() async {
    return authDataSource.getAccessToken();
  }

  @override
  Future<AuthCredential?> getAuthState() async {
    return authDataSource.getAuthState().then((value) => value?.toEntity());
  }

  @override
  Future<AuthCredential?> login(LoginData loginData) async {
    return authDataSource.login(loginData).then((value) => value?.toEntity());
  }

  @override
  Future<void> logout() async {
    await authDataSource.logout();
  }

  @override
  Future<AuthCredential?> registerUser(SignUpData signUpData) async {
    return authDataSource.registerUser(signUpData).then((value) => value?.toEntity());
  }

  @override
  Future<void> resendConfirmationCode() async {
    authDataSource.resendConfirmationCode();
  }
}