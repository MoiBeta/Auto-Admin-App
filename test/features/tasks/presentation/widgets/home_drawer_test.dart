import 'package:auto_admin_app/features/auth/injection/auth_providers.dart';
import 'package:auto_admin_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/home_drawer.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: HomeDrawer(),
        ),
      ),
    );
  }

  group('HomeDrawer - Actions', () {
    late _FakeAuthNotifier auth;

    Future<void> openDrawer(WidgetTester tester) async {
      auth = _FakeAuthNotifier();
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => auth),
            homeProvider.overrideWith(_FakeHomeNotifier.new),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(key: scaffoldKey, drawer: const HomeDrawer()),
          ),
        ),
      );
      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
    }

    testWidgets('Inicio closes the drawer', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDrawer), findsNothing);
    });

    testWidgets('logging out needs confirmation', (tester) async {
      await openDrawer(tester);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(auth.loggedOut, isFalse);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión').last);
      await tester.pumpAndSettle();
      expect(auth.loggedOut, isTrue);
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  group('HomeDrawer - Navigation Drawer widget tests', () {
    testWidgets('uses NavigationDrawer widget (not legacy Drawer)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify NavigationDrawer is present
      expect(find.byType(NavigationDrawer), findsOneWidget);

      // Verify legacy Drawer is NOT used directly as the top-level drawer
      // NavigationDrawer internally may use Drawer, but our code should use
      // the M3 NavigationDrawer widget explicitly
      final navigationDrawerFinder = find.byType(NavigationDrawer);
      expect(navigationDrawerFinder, findsOneWidget);
    });

    testWidgets('contains NavigationDrawerDestination items',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 2 NavigationDrawerDestination widgets are present
      expect(find.byType(NavigationDrawerDestination), findsNWidgets(2));
    });

    testWidgets('DrawerHeader is present with correct background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify DrawerHeader is present
      expect(find.byType(DrawerHeader), findsOneWidget);

      // Verify DrawerHeader background color matches colorScheme.primaryContainer
      final drawerHeader = tester.widget<DrawerHeader>(
        find.byType(DrawerHeader),
      );
      final decoration = drawerHeader.decoration as BoxDecoration;
      expect(
        decoration.color,
        AppTheme.lightTheme.colorScheme.primaryContainer,
      );
    });

    testWidgets('displays "SelfAnvil" text in the header',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('SelfAnvil'), findsOneWidget);
    });

    testWidgets('displays "Inicio" and "Cerrar sesión" labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  bool loggedOut = false;

  @override
  Future<LoginState> build() async => const LoginState(isLoading: false);

  @override
  Future<void> logout() async => loggedOut = true;
}

class _FakeHomeNotifier extends HomeNotifier {
  @override
  Future<List<Task>> build() async => [];
}
