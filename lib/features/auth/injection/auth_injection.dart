import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_login.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_logout.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/auth_register.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/change_password.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/confirm_email.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/get_auth_state.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/resend_confirmation_code.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Provider<AuthDataSource> authSourceProvider =
    Provider<AuthDataSource>((_) => FirebaseAuthDataSource());

Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepositoryImpl(ref.watch(authSourceProvider)));

Provider<AuthLogin> authLoginUseCaseProvider =
    Provider<AuthLogin>((ref) => AuthLogin(ref.watch(authRepositoryProvider)));

Provider<AuthLogout> authLogoutUseCaseProvider = Provider<AuthLogout>(
    (ref) => AuthLogout(ref.watch(authRepositoryProvider)));

Provider<AuthRegister> authRegisterUseCaseProvider = Provider<AuthRegister>(
    (ref) => AuthRegister(ref.watch(authRepositoryProvider)));

Provider<ConfirmEmail> confirmEmailUseCaseProvider = Provider<ConfirmEmail>(
    (ref) => ConfirmEmail(ref.watch(authRepositoryProvider)));

Provider<GetAuthState> getAuthStateUseCaseProvider = Provider<GetAuthState>(
    (ref) => GetAuthState(ref.watch(authRepositoryProvider)));

Provider<ResendConfirmationCode> resendConfirmationCodeUseCaseProvider =
    Provider<ResendConfirmationCode>(
        (ref) => ResendConfirmationCode(ref.watch(authRepositoryProvider)));

Provider<ChangePassword> changePasswordUseCaseProvider =
    Provider<ChangePassword>(
        (ref) => ChangePassword(ref.watch(authRepositoryProvider)));

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, LoginState>(() => AuthNotifier());
