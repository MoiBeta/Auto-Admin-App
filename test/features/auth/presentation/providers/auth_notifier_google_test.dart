import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:auto_admin_app/core/errors/global_error_notifier.dart';
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';
import 'package:auto_admin_app/features/auth/domain/repository/auth_repository.dart';
import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AuthRepository {
  Future<AuthCredential?> Function() onGoogle = () async => null;

  @override
  Future<AuthCredential?> getAuthState() async => null;

  @override
  Future<AuthCredential?> loginWithGoogle() => onGoogle();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;
  final errors = <AppError>[];

  setUp(() async {
    repository = _FakeRepository();
    errors.clear();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen<AppError?>(globalErrorProvider, (_, next) {
      if (next != null) errors.add(next);
    });
    await container.read(authNotifierProvider.future);
  });

  tearDown(() => container.dispose());

  LoginStateView state() =>
      LoginStateView(container.read(authNotifierProvider).value!);

  test('signs in with the account returned by Google', () async {
    repository.onGoogle = () async => AuthCredential(
          id: '1',
          fullName: 'Ana',
          email: 'ana@gmail.com',
          isEmailConfirmed: null,
        );

    await container.read(authNotifierProvider.notifier).loginWithGoogle();

    expect(state().email, 'ana@gmail.com');
    expect(state().isLoading, isFalse);
    expect(errors, isEmpty);
  });

  test('closing the picker is not an error', () async {
    await container.read(authNotifierProvider.notifier).loginWithGoogle();

    expect(state().email, isNull);
    expect(state().isLoading, isFalse);
    expect(errors, isEmpty);
  });

  test('a failure is reported and stops the loading state', () async {
    repository.onGoogle = () async => throw const AppException(AppError(
          message: 'No se pudo iniciar sesión con Google.',
          type: AppErrorType.unknown,
        ));

    await container.read(authNotifierProvider.notifier).loginWithGoogle();

    expect(state().isLoading, isFalse);
    expect(errors.single.message, 'No se pudo iniciar sesión con Google.');
  });
}

/// The fields of LoginState the tests look at.
class LoginStateView {
  final bool isLoading;
  final String? email;

  LoginStateView(dynamic s)
      : isLoading = s.isLoading as bool,
        email = s.credentials?.email as String?;
}
