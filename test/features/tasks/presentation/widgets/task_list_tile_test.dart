import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/task_list_tile.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Task testTask;

  setUp(() {
    testTask = Task(
      id: 'test-task-1',
      userId: 'user-1',
      title: 'Complete unit tests',
      startDate: DateTime(2024, 1, 15),
      completed: false,
      taskFrequency: TaskFrequency.daily,
      priority: 100,
    );
  });

  Widget buildTestWidget(Task task) {
    return ProviderScope(
      overrides: [
        selectedDateProvider.overrideWithValue(DateTime(2024, 1, 15)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskListTile(task: task),
          ),
        ),
      ),
    );
  }

  group('TaskListTile - Card structure and elevation', () {
    testWidgets('renders a Card widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Card has elevation of 1', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 1);
    });

    testWidgets('Card has RoundedRectangleBorder with 12dp radius',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });
  });

  group('TaskListTile - Semantic labels', () {
    testWidgets('has semantic label with task title and pending state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      // Find the Semantics widget that contains the expected label
      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'Complete unit tests, pendiente'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('has semantic label with completed state when task is done',
        (WidgetTester tester) async {
      final completedTask = testTask.copyWith(completed: true);

      await tester.pumpWidget(buildTestWidget(completedTask));
      await tester.pumpAndSettle();

      final semanticsFinder = find.bySemanticsLabel(
        RegExp(r'Complete unit tests, completada'),
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });

  group('TaskListTile - Touch target sizes (48dp minimum)', () {
    testWidgets('checkbox area meets 48x48dp minimum',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      final inkResponseSize = tester.getSize(find.byType(InkResponse).first);
      expect(inkResponseSize.width, greaterThanOrEqualTo(48));
      expect(inkResponseSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('menu anchor trigger area meets 48x48dp minimum',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      // The MenuAnchor builder wraps its child in a SizedBox(48x48) with GestureDetector
      final gestureDetectorSize =
          tester.getSize(find.byType(GestureDetector).first);
      expect(gestureDetectorSize.width, greaterThanOrEqualTo(48));
      expect(gestureDetectorSize.height, greaterThanOrEqualTo(48));
    });
  });

  group('TaskListTile - AnimatedDefaultTextStyle for title', () {
    testWidgets('uses AnimatedDefaultTextStyle for task title animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedDefaultTextStyle), findsWidgets);

      // Find the AnimatedDefaultTextStyle that contains the task title text
      final animatedTextWidgets = tester
          .widgetList<AnimatedDefaultTextStyle>(
              find.byType(AnimatedDefaultTextStyle))
          .where((widget) {
        final textFinder = find.descendant(
          of: find.byWidget(widget),
          matching: find.text('Complete unit tests'),
        );
        return textFinder.evaluate().isNotEmpty;
      });

      expect(animatedTextWidgets, isNotEmpty);
    });

    testWidgets('AnimatedDefaultTextStyle has 200ms duration',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpAndSettle();

      // Find AnimatedDefaultTextStyle containing the title
      final animatedTextWidgets = tester
          .widgetList<AnimatedDefaultTextStyle>(
              find.byType(AnimatedDefaultTextStyle))
          .where((widget) {
        final textFinder = find.descendant(
          of: find.byWidget(widget),
          matching: find.text('Complete unit tests'),
        );
        return textFinder.evaluate().isNotEmpty;
      });

      expect(animatedTextWidgets, isNotEmpty);
      final titleAnimatedText = animatedTextWidgets.first;
      expect(
        titleAnimatedText.duration,
        const Duration(milliseconds: 200),
      );
    });
  });
}
