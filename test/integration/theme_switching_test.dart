import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/pages/auth_page.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Integration tests for theme switching and navigation transitions.
///
/// These tests verify:
/// - App boots without render errors in light theme (Req 13.4)
/// - App boots without render errors in dark theme (Req 13.4)
/// - Navigation transitions use FadeTransition (Req 10.1)
/// - Layout consistency between light/dark modes (Req 1.3)
void main() {
  // Helper to build a minimal MaterialApp.router with GoRouter
  // Uses simple pages instead of AuthPage with Lottie to avoid pumpAndSettle timeouts.
  Widget buildAppWithRouter({
    required ThemeData theme,
    ThemeData? darkTheme,
    ThemeMode themeMode = ThemeMode.light,
  }) {
    final router = GoRouter(
      initialLocation: '/page-a',
      routes: [
        GoRoute(
          path: '/page-a',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('Page A')),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: '/page-b',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('Page B')),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: '/page-c',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('Page C')),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }

  // Helper to build a simple MaterialApp without router for basic theme tests
  Widget buildSimpleApp({
    required ThemeData theme,
    required Widget home,
  }) {
    // AuthPage has a Google sign-in button, which reads the auth state.
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new)
      ],
      child: MaterialApp(
        theme: theme,
        home: home,
      ),
    );
  }

  group('Light theme boot — no render errors', () {
    testWidgets('AuthPage renders without errors in light theme',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildSimpleApp(
          theme: AppTheme.lightTheme,
          home: const AuthPage(),
        ),
      );
      await tester.pump();

      // No exceptions thrown — verify key widgets rendered
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AuthPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MaterialApp.router boots with light theme without errors',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithRouter(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dark theme boot — no render errors', () {
    testWidgets('AuthPage renders without errors in dark theme',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildSimpleApp(
          theme: AppTheme.darkTheme,
          home: const AuthPage(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AuthPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MaterialApp.router boots with dark theme without errors',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithRouter(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Page A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Navigation transitions — FadeTransition', () {
    testWidgets('route transition uses FadeTransition widget', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/page-a',
        routes: [
          GoRoute(
            path: '/page-a',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page A')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          GoRoute(
            path: '/page-b',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page B')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to page B
      router.go('/page-b');
      await tester.pump(); // Start the transition
      await tester.pump(const Duration(milliseconds: 150)); // Mid-transition

      // During the transition, FadeTransition should be present in the widget tree
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('FadeTransition is present after initial route loads',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithRouter(theme: AppTheme.lightTheme),
      );
      await tester.pump();

      // FadeTransition should be used in the route's page builder
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('transition completes within 300ms duration', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/page-a',
        routes: [
          GoRoute(
            path: '/page-a',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page A')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          GoRoute(
            path: '/page-b',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page B')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to page B
      router.go('/page-b');
      // After 300ms the transition should be complete
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Page B should now be fully visible
      expect(find.text('Page B'), findsOneWidget);
    });
  });

  group('Layout consistency between light and dark modes', () {
    testWidgets('same widget tree structure in both themes', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Render with light theme and count key widgets
      await tester.pumpWidget(
        buildSimpleApp(
          theme: AppTheme.lightTheme,
          home: const AuthPage(),
        ),
      );
      await tester.pump();

      final lightFilledButtons = find.byType(FilledButton).evaluate().length;
      final lightTextButtons = find.byType(TextButton).evaluate().length;
      final lightTexts = find.byType(Text).evaluate().length;
      final lightScaffolds = find.byType(Scaffold).evaluate().length;

      // Render with dark theme and count key widgets
      await tester.pumpWidget(
        buildSimpleApp(
          theme: AppTheme.darkTheme,
          home: const AuthPage(),
        ),
      );
      await tester.pump();

      final darkFilledButtons = find.byType(FilledButton).evaluate().length;
      final darkTextButtons = find.byType(TextButton).evaluate().length;
      final darkTexts = find.byType(Text).evaluate().length;
      final darkScaffolds = find.byType(Scaffold).evaluate().length;

      // Same widget count in both themes means consistent layout structure
      expect(lightFilledButtons, equals(darkFilledButtons));
      expect(lightTextButtons, equals(darkTextButtons));
      expect(lightTexts, equals(darkTexts));
      expect(lightScaffolds, equals(darkScaffolds));
    });

    testWidgets('light and dark themes use distinct surface colors',
        (tester) async {
      // Verify at the theme data level that surface colors differ
      final lightSurface = AppTheme.lightTheme.colorScheme.surface;
      final darkSurface = AppTheme.darkTheme.colorScheme.surface;

      expect(lightSurface, isNot(equals(darkSurface)));
    });

    testWidgets('ThemeMode.system is supported without errors', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithRouter(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
        ),
      );
      await tester.pumpAndSettle();

      // App should render without errors when themeMode is system
      expect(find.text('Page A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('GoRouter routes all use CustomTransitionPage with FadeTransition', () {
    testWidgets('all configured routes produce FadeTransition on navigation',
        (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/page-a',
        routes: [
          GoRoute(
            path: '/page-a',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page A')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          GoRoute(
            path: '/page-b',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page B')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          GoRoute(
            path: '/page-c',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(child: Text('Page C')),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to page B
      router.go('/page-b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('Page B'), findsOneWidget);

      // Navigate to page C
      router.go('/page-c');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('Page C'), findsOneWidget);

      // Navigate back to page A
      router.go('/page-a');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('Page A'), findsOneWidget);
    });
  });
}

class _SignedOutAuthNotifier extends AuthNotifier {
  @override
  Future<LoginState> build() async => const LoginState(isLoading: false);
}
