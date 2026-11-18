import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/auth_page.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthNotifier extends AuthNotifier {
  int googleLogins = 0;

  @override
  Future<LoginState> build() async => const LoginState(isLoading: false);

  @override
  Future<void> loginWithGoogle() async => googleLogins++;
}

void main() {
  late _FakeAuthNotifier auth;

  Widget buildTestWidget({ThemeData? theme}) {
    auth = _FakeAuthNotifier();
    return ProviderScope(
      overrides: [authNotifierProvider.overrideWith(() => auth)],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: const MediaQuery(
          data: MediaQueryData(size: Size(400, 900)),
          child: AuthPage(),
        ),
      ),
    );
  }

  testWidgets('offers signing in with Google', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pump();

    expect(auth.googleLogins, 1);
  });

  group('AuthPage - Button Hierarchy', () {
    testWidgets('uses FilledButton for primary login action', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('uses TextButton for secondary register action',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('FilledButton displays "Iniciar sesión"', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final filledButton = find.byType(FilledButton);
      expect(filledButton, findsOneWidget);

      final buttonText = find.descendant(
        of: filledButton,
        matching: find.text('Iniciar sesión'),
      );
      expect(buttonText, findsOneWidget);
    });

    testWidgets('TextButton displays "Crear cuenta"', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final textButton = find.byType(TextButton);
      expect(textButton, findsOneWidget);

      final buttonText = find.descendant(
        of: textButton,
        matching: find.text('Crear cuenta'),
      );
      expect(buttonText, findsOneWidget);
    });
  });

  group('AuthPage - Text Content', () {
    testWidgets('displays "Toma el control de tu vida" heading',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Toma el control de tu vida'), findsOneWidget);
    });

    testWidgets('displays "Empieza ahora..." subtitle', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Empieza ahora...'), findsOneWidget);
    });
  });

  group('AuthPage - Typography Roles', () {
    testWidgets('heading uses headlineMedium text style', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final headingFinder = find.text('Toma el control de tu vida');
      final headingWidget = tester.widget<Text>(headingFinder);

      // The widget sets style from Theme.of(context).textTheme.headlineMedium
      // which has fontSize 28 and fontWeight w400
      expect(headingWidget.style, isNotNull);
      expect(headingWidget.style!.fontSize, 28);
      expect(headingWidget.style!.fontWeight, FontWeight.w400);
    });

    testWidgets('subtitle uses bodyLarge text style', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final subtitleFinder = find.text('Empieza ahora...');
      final subtitleWidget = tester.widget<Text>(subtitleFinder);

      // The widget sets style from Theme.of(context).textTheme.bodyLarge
      // which has fontSize 16 and fontWeight w400
      expect(subtitleWidget.style, isNotNull);
      expect(subtitleWidget.style!.fontSize, 16);
      expect(subtitleWidget.style!.fontWeight, FontWeight.w400);
    });
  });

  group('AuthPage - No Hardcoded Colors', () {
    testWidgets('Scaffold does not have explicit backgroundColor set',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsOneWidget);

      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      // No hardcoded backgroundColor — relies on theme scaffoldBackgroundColor
      expect(scaffold.backgroundColor, isNull);
    });

    testWidgets('renders correctly with dark theme (no hardcoded colors)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget(theme: AppTheme.darkTheme));
      await tester.pump();

      // If there were hardcoded colors, the widget would render
      // fine but not adapt to dark theme. Verify it renders without error.
      expect(find.byType(AuthPage), findsOneWidget);
      expect(find.text('Toma el control de tu vida'), findsOneWidget);
    });
  });
}
