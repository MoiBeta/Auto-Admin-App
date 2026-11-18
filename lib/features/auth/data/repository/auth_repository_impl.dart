import 'dart:developer';

import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/google_id_token_source.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSource authDataSource;
  final GoogleIdTokenSource googleIdTokenSource;
  AuthRepositoryImpl(this.authDataSource, this.googleIdTokenSource);

  @override
  Future<bool> changePassword(ChangePasswordData changePasswordData) async {
    return authDataSource.changePassword(changePasswordData);
  }

  @override
  Future<bool> confirmEmail() async {
    return authDataSource.confirmEmail();
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
  Future<AuthCredential?> loginWithGoogle() async {
    final idToken = await googleIdTokenSource.getIdToken();
    if (idToken == null) return null;
    final model = await authDataSource.loginWithGoogle(idToken);
    return model?.toEntity();
  }

  @override
  Future<void> logout() async {
    await authDataSource.logout();
    try {
      await googleIdTokenSource.signOut();
    } catch (e) {
      // The session is already closed; only the account picker is affected.
      log('Failed to sign out from Google: $e');
    }
  }

  @override
  Future<AuthCredential?> registerUser(SignUpData signUpData) async {
    return authDataSource
        .registerUser(signUpData)
        .then((value) => value?.toEntity());
  }

  @override
  Future<void> resendConfirmationCode() async {
    authDataSource.resendConfirmationCode();
  }
}
