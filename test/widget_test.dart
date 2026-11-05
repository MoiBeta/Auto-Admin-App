// Basic smoke test for the SelfAnvil app.
//
// Verifies that the app can be instantiated without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auto_admin_app/main.dart';

void main() {
  testWidgets('App smoke test — MyApp builds without errors',
      (WidgetTester tester) async {
    // MyApp requires a ProviderScope (Riverpod) to function.
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // Verify that the app builds without throwing.
    // The app will show either the auth screen or home screen
    // depending on auth state, both are valid.
    await tester.pump();
  });
}
