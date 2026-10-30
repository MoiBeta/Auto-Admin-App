import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/adding_task_screen.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  /// Builds the AddingTaskScreen wrapped in ProviderScope with homeProvider
  /// overridden to avoid real async dependencies.
  Widget buildTestWidget({bool saves = true}) {
    return ProviderScope(
      overrides: [
        homeProvider.overrideWith(
          () => _FakeHomeNotifier(saves: saves),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AddingTaskScreen(),
      ),
    );
  }

  group('AddingTaskScreen - Saving', () {
    testWidgets('keeps the form and its content when saving fails',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(saves: false));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Leer');
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(find.byType(AddingTaskScreen), findsOneWidget);
      expect(find.text('Leer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AddingTaskScreen - Widget Structure', () {
    testWidgets('uses DropdownMenu<TaskFrequency> instead of DropdownButton',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify DropdownMenu<TaskFrequency> is present
      expect(find.byType(DropdownMenu<TaskFrequency>), findsOneWidget);

      // Verify DropdownButton is NOT used
      expect(find.byType(DropdownButton<TaskFrequency>), findsNothing);
    });

    testWidgets('form is wrapped in a Card with elevation 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Card widget exists
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      // Verify Card has elevation 0
      final Card cardWidget = tester.widget(cardFinder);
      expect(cardWidget.elevation, 0);
    });

    testWidgets('Card uses surfaceContainerLow color', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final cardFinder = find.byType(Card);
      final Card cardWidget = tester.widget(cardFinder);

      final expectedColor = AppTheme.lightTheme.colorScheme.surfaceContainerLow;
      expect(cardWidget.color, expectedColor);
    });

    testWidgets('form fields have minimum height of 56dp', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find all TextFormField widgets
      final formFields = find.byType(TextFormField);
      expect(formFields, findsWidgets);

      // Check that each form field meets the 56dp minimum height
      for (int i = 0; i < tester.widgetList(formFields).length; i++) {
        final size = tester.getSize(formFields.at(i));
        expect(
          size.height,
          greaterThanOrEqualTo(56.0),
          reason: 'TextFormField at index $i should have min height 56dp',
        );
      }
    });

    testWidgets('contains TextFormField widgets for input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should have at least the title, date, and reminder fields
      final formFields = find.byType(TextFormField);
      expect(formFields, findsAtLeast(3));
    });

    testWidgets('uses FilledButton.tonal for save action', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // FilledButton.tonal creates a FilledButton with tonal styling
      final filledButtonFinder = find.byType(FilledButton);
      expect(filledButtonFinder, findsOneWidget);

      // Verify it contains the expected text
      final buttonTextFinder = find.descendant(
        of: filledButtonFinder,
        matching: find.text('Agregar'),
      );
      expect(buttonTextFinder, findsOneWidget);
    });

    testWidgets('Card is wrapped with formHorizontal padding', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // The Card's parent Padding should use formHorizontal (24dp)
      final cardFinder = find.byType(Card);
      final paddingFinder = find.ancestor(
        of: cardFinder,
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsWidgets);

      // The nearest Padding ancestor of Card should have horizontal 24dp
      // (Spacing.formHorizontal)
      final Padding paddingWidget = tester.widget(paddingFinder.first);
      final EdgeInsets padding = paddingWidget.padding as EdgeInsets;
      expect(padding.left, 24.0);
      expect(padding.right, 24.0);
    });
  });
}

/// A fake HomeNotifier that returns an empty task list without
/// requiring real dependencies (repositories, use cases, etc.).
class _FakeHomeNotifier extends HomeNotifier {
  final bool saves;

  _FakeHomeNotifier({this.saves = true});

  @override
  Future<List<Task>> build() async {
    return [];
  }

  @override
  Future<Task?> createTask({
    required String title,
    required DateTime startDate,
    required TaskFrequency frequency,
    DateTime? reminderDate,
    List<String>? subtasks,
  }) async =>
      saves
          ? Task(
              id: 'new',
              userId: 'u',
              title: title,
              startDate: startDate,
              completed: false,
              taskFrequency: frequency,
              priority: 100,
            )
          : null;
}
