import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/home_drawer.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/task_list_tile.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    AsyncValue<List<Task>> tasksList = ref.watch(homeProvider);
    DateTime selectedDate = ref.watch(selectedDateProvider);
    final dates = getDateTimeRange();
    return Scaffold(
      drawer: HomeDrawer(),
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ...dates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  final colorScheme = Theme.of(context).colorScheme;

                  final currentMonth =
                      intl.DateFormat('MMM', 'es').format(date);

                  final previousMonth = index > 0
                      ? intl.DateFormat('MMM', 'es').format(dates[index - 1])
                      : null;

                  final shouldShowMonth =
                      index == 0 || currentMonth != previousMonth;

                  final isSelected = selectedDate.month == date.month &&
                      selectedDate.day == date.day;

                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).selectDate(date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                        horizontal: Spacing.chipSpacing / 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.secondaryContainer
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (shouldShowMonth)
                            Text(
                              intl.DateFormat('MMM', 'es')
                                  .format(date)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          Text(
                            intl.DateFormat('EEE', 'es')
                                .format(date)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            intl.DateFormat('dd').format(date),
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screenHorizontal,
                ),
                child: tasksList.when(
                  data: (data) => ReorderableListView(
                    onReorderItem: (int oldIndex, int newIndex) async {
                      ref.read(homeProvider.notifier).updateTaskPriorities(
                          oldIndex: oldIndex, newIndex: newIndex);
                    },
                    footer: const SizedBox(
                      height: 75,
                    ),
                    children: [
                      ...data.asMap().entries.map(
                            (entry) => Padding(
                              key: ValueKey('${entry.value.id}_${entry.key}'),
                              padding: const EdgeInsets.only(
                                bottom: Spacing.listItemSpacing,
                              ),
                              child: TaskListTile(
                                task: entry.value,
                              ),
                            ),
                          ),
                    ],
                  ),
                  error: (error, trace) => Center(
                    child: Text(error.toString()),
                  ),
                  loading: () => Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar nueva tarea',
        child: const Icon(Icons.add),
        onPressed: () {
          context.pushNamed(Routes.addingTask);
        },
      ),
    );
  }

  List<DateTime> getDateTimeRange() {
    List<DateTime> datesList = [];
    for (int i = -3; i < 4; i++) {
      datesList.add(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ).add(Duration(days: i)));
    }
    return datesList;
  }
}
