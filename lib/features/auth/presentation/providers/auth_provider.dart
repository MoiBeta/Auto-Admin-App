import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_logout.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_register.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/change_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/confirm_email.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/get_auth_state.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/resend_confirmation_code.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<LoginState> {
  final GetAuthState _getAuthState;
  final AuthLogin _authLogin;
  final AuthRegister _authRegister;
  final ConfirmEmail _confirmEmail;
  final ResendConfirmationCode _resendConfirmationCode;
  final AuthLogout _authLogout;
  final ChangePassword _changePassword;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  AuthNotifier(
    this._getAuthState,
    this._authLogin,
    this._authRegister,
    this._confirmEmail,
    this._resendConfirmationCode,
    this._authLogout,
    this._changePassword,
  ) : super(LoginState()) {
    _check();
  }

  Future<void> _check() async {
    state = state.copyWith(
      isLoading: true,
    );
    AuthCredential? authCredential = await _getAuthState();
    state = state.copyWith(
      isLoading: false,
      credentials: authCredential,
    );
  }

  Future<void> login() async {
    state = state.copyWith(
      isLoading: true,
    );
    AuthCredential? authCredential = await _authLogin(LoginData(
      email: emailController.text,
      password: passwordController.text,
    ));
    state = state.copyWith(
      isLoading: false,
      credentials: authCredential,
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
    );
    AuthCredential? authCredential = await _authRegister.call(
      SignUpData(email: email, password: password, fullName: fullName),
    );
    state = state.copyWith(
      isLoading: false,
      credentials: authCredential,
    );
  }

  Future<void> confirmEmail() async {
    state = state.copyWith(
      isLoading: true,
    );
    bool confirmed = await _confirmEmail.call();
    state = state.copyWith(
      isLoading: false,
      credentials: state.credentials?.copyWith(
        isEmailConfirmed: confirmed,
      ),
    );
  }

  Future<void> resendConfirmationCode() async {
    return _resendConfirmationCode.call();
  }

  Future<void> logout() async {
    await _authLogout();
    state = state.copyWith(
      credentials: null,
    );
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
    );
    bool success = await _changePassword(
      ChangePasswordData(oldPassword: oldPassword, newPassword: newPassword),
    );
    state = state.copyWith(
      isLoading: false,
    );
    return success;
  }
}

class LoginState {
  final AuthCredential? credentials;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.hasError = false,
    this.credentials,
    this.errorMessage,
  });

  LoginState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    AuthCredential? credentials,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      credentials: credentials ?? this.credentials,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
