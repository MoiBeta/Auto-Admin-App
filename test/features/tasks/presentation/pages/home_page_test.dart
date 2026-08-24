import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/pages/home_page.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Validates: Requirements 3.1, 14.1, 13.2

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final mockTasks = [
    Task(
      id: 'task-1',
      userId: 'user-1',
      title: 'Test Task 1',
      startDate: today,
      completed: false,
      taskFrequency: TaskFrequency.daily,
      priority: 100,
    ),
    Task(
      id: 'task-2',
      userId: 'user-1',
      title: 'Test Task 2',
      startDate: today,
      completed: true,
      taskFrequency: TaskFrequency.none,
      priority: 200,
    ),
  ];

  Widget buildTestableHomePage({
    required ThemeData theme,
    List<Task> tasks = const [],
  }) {
    return ProviderScope(
      overrides: [
        homeProvider.overrideWith(() => _MockHomeNotifier(tasks)),
        selectedDateProvider.overrideWithValue(today),
      ],
      child: MaterialApp(
        theme: theme,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage renders without errors', () {
    testWidgets('renders correctly with light theme', (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly with dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.darkTheme),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Task items use Card widget (Requirement 3.1)', () {
    testWidgets('Card widget is present when tasks are loaded', (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(
          theme: AppTheme.lightTheme,
          tasks: mockTasks,
        ),
      );
      await tester.pumpAndSettle();

      // TaskListTile uses Card widget, not raw Container
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Card has correct shape with 12dp border radius',
        (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(
          theme: AppTheme.lightTheme,
          tasks: mockTasks,
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(find.byType(Card).first);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });
  });

  group('Date selector uses theme color tokens (Requirements 14.1, 13.2)', () {
    testWidgets('AnimatedContainer is used for date chips', (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      // The date selector uses AnimatedContainer for each date chip
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets(
        'selected date chip uses secondaryContainer color in light theme',
        (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      // Find the selected container (with secondaryContainer background)
      final hasSelectedContainer = animatedContainers.any((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.color ==
            AppTheme.lightTheme.colorScheme.secondaryContainer;
      });

      expect(hasSelectedContainer, isTrue);
    });

    testWidgets(
        'selected date chip uses secondaryContainer color in dark theme',
        (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.darkTheme),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      // Find the selected container (with secondaryContainer background)
      final hasSelectedContainer = animatedContainers.any((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.color ==
            AppTheme.darkTheme.colorScheme.secondaryContainer;
      });

      expect(hasSelectedContainer, isTrue);
    });

    testWidgets('unselected date chips use surfaceContainerHigh color',
        (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      final animatedContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      // At least some containers should use surfaceContainerHigh (unselected)
      final unselectedContainers = animatedContainers.where((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.color ==
            AppTheme.lightTheme.colorScheme.surfaceContainerHigh;
      });

      // There are 7 date chips total, 1 selected, 6 unselected
      expect(unselectedContainers.length, greaterThanOrEqualTo(5));
    });

    testWidgets('date chips have minimum 48x48dp constraints', (tester) async {
      await tester.pumpWidget(
        buildTestableHomePage(theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsWidgets);

      // Verify at least one AnimatedContainer has minHeight/minWidth of 48
      final container =
          tester.widget<AnimatedContainer>(animatedContainers.first);
      final constraints = container.constraints;
      expect(constraints?.minWidth, greaterThanOrEqualTo(48));
      expect(constraints?.minHeight, greaterThanOrEqualTo(48));
    });
  });
}

/// Mock HomeNotifier that returns a predefined list of tasks
/// without depending on network/backend services.
class _MockHomeNotifier extends HomeNotifier {
  final List<Task> _tasks;

  _MockHomeNotifier(this._tasks);

  @override
  Future<List<Task>> build() async {
    return _tasks;
  }
}
