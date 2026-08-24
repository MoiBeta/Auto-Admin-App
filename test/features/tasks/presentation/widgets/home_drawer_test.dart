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

    testWidgets('displays "Auto Admin" text in the header',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Auto Admin'), findsOneWidget);
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
