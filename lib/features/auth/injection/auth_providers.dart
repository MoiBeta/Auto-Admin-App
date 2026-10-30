import 'package:auto_admin_app/core/network/dio_client.dart';
import 'package:auto_admin_app/core/network/interceptors/auth_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/error_interceptor.dart';
import 'package:auto_admin_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/auth_remote_data_source.dart';
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
import 'package:auto_admin_app/global/di/global_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authBaseUrlProvider =
    Provider<String>((ref) => dotenv.env['AUTH_BASE_URL'] ?? '');

final refreshDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(authBaseUrlProvider);
  Dio dio = Dio(apiOptions(baseUrl));
  final tokenManager = ref.watch(tokenManagerProvider);
  dio.interceptors.add(RefreshInterceptor(tokenManager));
  return dio;
});

final authDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(authBaseUrlProvider);
  final dio = Dio(apiOptions(baseUrl));
  final tokenManager = ref.watch(tokenManagerProvider);
  final refreshDio = ref.watch(refreshDioProvider);

  dio.interceptors.addAll([
    AuthInterceptor(
      tokenManager: tokenManager,
      refreshDio: refreshDio,
      requestDio: dio,
      onSessionExpired: () =>
          ref.read(authNotifierProvider.notifier).sessionExpired(),
    ),
    ErrorInterceptor(),
  ]);
  return dio;
});

final authDioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(authDioProvider);
  return DioClient(dio);
});

final Provider<AuthDataSource> authSourceProvider = Provider<AuthDataSource>(
  (ref) => AuthRemoteDataSource(
    tokenManager: ref.watch(
      tokenManagerProvider,
    ),
    client: ref.watch(authDioClientProvider),
  ),
);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
        (ref) => AuthRepositoryImpl(ref.watch(authSourceProvider)));

final Provider<AuthLogin> authLoginUseCaseProvider =
    Provider<AuthLogin>((ref) => AuthLogin(ref.watch(authRepositoryProvider)));

final Provider<AuthLogout> authLogoutUseCaseProvider = Provider<AuthLogout>(
    (ref) => AuthLogout(ref.watch(authRepositoryProvider)));

final Provider<AuthRegister> authRegisterUseCaseProvider =
    Provider<AuthRegister>(
        (ref) => AuthRegister(ref.watch(authRepositoryProvider)));

final Provider<ConfirmEmail> confirmEmailUseCaseProvider =
    Provider<ConfirmEmail>(
        (ref) => ConfirmEmail(ref.watch(authRepositoryProvider)));

final Provider<GetAuthState> getAuthStateUseCaseProvider =
    Provider<GetAuthState>(
        (ref) => GetAuthState(ref.watch(authRepositoryProvider)));

final Provider<ResendConfirmationCode> resendConfirmationCodeUseCaseProvider =
    Provider<ResendConfirmationCode>(
        (ref) => ResendConfirmationCode(ref.watch(authRepositoryProvider)));

final Provider<ChangePassword> changePasswordUseCaseProvider =
    Provider<ChangePassword>(
        (ref) => ChangePassword(ref.watch(authRepositoryProvider)));

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, LoginState>(() => AuthNotifier());
