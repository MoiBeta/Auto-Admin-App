import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/task_list_tile.dart';
import 'package:auto_admin_app/global/theme/app_theme.dart';
import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:auto_admin_app/global/widgets/forge/flame_edge.dart';
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

  group('TaskListTile - Subtasks', () {
    testWidgets('shows progress instead of an inert checkbox', (tester) async {
      await tester.pumpWidget(buildTestWidget(testTask.copyWith(subtasks: [
        Subtask(id: 's1', title: 'Uno', completed: true),
        Subtask(id: 's2', title: 'Dos', completed: false),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'1 de 2 subtareas')),
        findsOneWidget,
      );
    });
  });

  group('TaskListTile - Delete', () {
    testWidgets('deletes from the menu and offers to undo', (tester) async {
      final home = _RecordingHomeNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith(() => home),
            selectedDateProvider.overrideWithValue(DateTime(2024, 1, 15)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(body: TaskListTile(task: testTask)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Más opciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      expect(find.text('Borrar'), findsNothing, reason: 'the menu closes');
      expect(home.scheduled, ['test-task-1']);

      await tester.tap(find.text('Deshacer'));
      expect(home.undone, ['test-task-1']);
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

      final buttonSize = tester.getSize(find.byTooltip('Más opciones'));
      expect(buttonSize.width, greaterThanOrEqualTo(48));
      expect(buttonSize.height, greaterThanOrEqualTo(48));
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

  group('TaskListTile - Forge animation', () {
    Color? cardColor(WidgetTester tester) =>
        tester.widget<Card>(find.byType(Card).first).color;

    testWidgets('a task completed elsewhere is forged without animating',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(testTask));
      await tester.pumpWidget(
        buildTestWidget(testTask.copyWith(completed: true)),
      );

      expect(find.byType(FlameEdge), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(cardColor(tester), ForgePalette.steel);
    });

    Widget buildList(_TogglingHomeNotifier notifier, {bool noMotion = false}) {
      return ProviderScope(
        overrides: [
          selectedDateProvider.overrideWithValue(DateTime(2024, 1, 15)),
          homeProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: noMotion),
            child: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    for (final task in ref.watch(homeProvider).value ?? [])
                      TaskListTile(key: ValueKey(task.id), task: task),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('touching a task saves at once and ends forged',
        (tester) async {
      final notifier = _TogglingHomeNotifier(testTask);
      await tester.pumpWidget(buildList(notifier));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      // Saved before the first frame of the animation.
      expect(notifier.toggles, 1);
      await tester.pump();

      expect(find.byType(FlameEdge), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(find.byType(FlameEdge), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(cardColor(tester), ForgePalette.steel);
      expect(find.byIcon(Icons.check_box), findsOneWidget);
      expect(notifier.toggles, 1);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('with animations disabled no sweep starts', (tester) async {
      final notifier = _TogglingHomeNotifier(testTask);
      await tester.pumpWidget(buildList(notifier, noMotion: true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      await tester.pump();

      expect(find.byType(FlameEdge), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(cardColor(tester), ForgePalette.steel);
      expect(notifier.toggles, 1);
    });

    testWidgets('a task completed when the list loads starts forged',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(testTask.copyWith(completed: true)),
      );

      expect(find.byType(FlameEdge), findsNothing);
      expect(find.byType(Card), findsOneWidget);
      expect(cardColor(tester), ForgePalette.steel);
    });
  });
}

class _RecordingHomeNotifier extends HomeNotifier {
  final List<String> scheduled = [];
  final List<String> undone = [];

  @override
  Future<List<Task>> build() async => [];

  @override
  void scheduleDelete(Task task) => scheduled.add(task.id);

  @override
  void undoDelete(String taskId) => undone.add(taskId);
}

class _TogglingHomeNotifier extends HomeNotifier {
  final Task task;
  int toggles = 0;

  _TogglingHomeNotifier(this.task);

  @override
  Future<List<Task>> build() async => [task];

  @override
  Future<void> toggleTask({required Task task, required DateTime date}) async {
    toggles++;
    state = AsyncData([task.copyWith(completed: !task.completed)]);
  }
}
