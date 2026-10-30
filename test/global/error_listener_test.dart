import 'package:auto_admin_app/core/errors/global_message_notifier.dart';
import 'package:auto_admin_app/global/widgets/error_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows global messages such as foreground reminders',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => ErrorListener(child: child!),
          home: const Scaffold(),
        ),
      ),
    );

    container.read(globalMessageProvider.notifier).show('Leer: 20:00');
    await tester.pump();

    expect(find.text('Leer: 20:00'), findsOneWidget);
  });
}
