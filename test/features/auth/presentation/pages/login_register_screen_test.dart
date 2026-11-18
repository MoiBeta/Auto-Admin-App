import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/login_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/register_screen.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  String? loginEmail;
  bool registered = false;
  int googleLogins = 0;

  @override
  Future<LoginState> build() async => const LoginState(isLoading: false);

  @override
  Future<void> login({required String email, required String password}) async =>
      loginEmail = email;

  @override
  Future<void> loginWithGoogle() async => googleLogins++;

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async =>
      registered = true;
}

void main() {
  late _FakeAuthNotifier auth;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    auth = _FakeAuthNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('LoginScreen', () {
    testWidgets('does not submit an invalid form', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Escribe un correo válido'), findsOneWidget);
      expect(find.text('Escribe tu contraseña'), findsOneWidget);
      expect(auth.loginEmail, isNull);
    });

    testWidgets('submits a trimmed email', (tester) async {
      await pump(tester, const LoginScreen());
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.first);
      await tester.enterText(fields.first, ' ana@example.com ');
      await tester.enterText(fields.last, 'secret');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.loginEmail, 'ana@example.com');
    });

    testWidgets('signs in with Google', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.ensureVisible(find.text('Continuar con Google'));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.googleLogins, 1);
    });

    testWidgets('can show the password', (tester) async {
      await pump(tester, const LoginScreen());
      await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('fits a small screen, as with the keyboard open',
        (tester) async {
      tester.view.physicalSize = const Size(320, 260);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pump(tester, const RegisterScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not submit an invalid form', (tester) async {
      await pump(tester, const RegisterScreen());
      await tester.tap(find.text('Registrarse'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Escribe tu nombre'), findsOneWidget);
      expect(auth.registered, isFalse);
    });
  });
}
