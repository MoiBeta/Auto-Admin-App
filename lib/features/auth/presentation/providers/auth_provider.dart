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
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<LoginState> {
  late GetAuthState _getAuthState;
  late AuthLogin _authLogin;
  late AuthRegister _authRegister;
  late ConfirmEmail _confirmEmail;
  late ResendConfirmationCode _resendConfirmationCode;
  late AuthLogout _authLogout;
  late ChangePassword _changePassword;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Future<LoginState> build() async {
    _getAuthState = ref.watch(getAuthStateUseCaseProvider);
    _authLogin = ref.watch(authLoginUseCaseProvider);
    _authRegister = ref.watch(authRegisterUseCaseProvider);
    _confirmEmail = ref.watch(confirmEmailUseCaseProvider);
    _resendConfirmationCode = ref.watch(resendConfirmationCodeUseCaseProvider);
    _authLogout = ref.watch(authLogoutUseCaseProvider);
    _changePassword = ref.watch(changePasswordUseCaseProvider);
    AuthCredential? authCredential = await _getAuthState();
    return LoginState(
      isLoading: false,
      credentials: authCredential,
    );
  }

  Future<void> login() async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    AuthCredential? authCredential = await _authLogin(LoginData(
      email: emailController.text,
      password: passwordController.text,
    ));
    state = AsyncData(
      state.value!.copyWith(
        isLoading: false,
        credentials: authCredential,
      ),
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    AuthCredential? authCredential = await _authRegister.call(
      SignUpData(email: email, password: password, fullName: fullName),
    );
    state = AsyncData(
      state.value!.copyWith(
        isLoading: false,
        credentials: authCredential,
      ),
    );
  }

  Future<void> confirmEmail() async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    bool confirmed = await _confirmEmail.call();
    state = AsyncData(
      state.value!.copyWith(
        isLoading: false,
        credentials: state.value?.credentials?.copyWith(
          isEmailConfirmed: confirmed,
        ),
      ),
    );
  }

  Future<void> resendConfirmationCode() async {
    return _resendConfirmationCode.call();
  }

  Future<void> logout() async {
    await _authLogout();
    state = AsyncData(
      state.value!.copyWith(
        credentials: null,
      ),
    );
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = AsyncData(
      state.value!.copyWith(
        isLoading: true,
      ),
    );
    bool success = await _changePassword(
      ChangePasswordData(oldPassword: oldPassword, newPassword: newPassword),
    );
    state = AsyncData(
      state.value!.copyWith(
        isLoading: false,
      ),
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
    this.isLoading = true,
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
