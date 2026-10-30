import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/core/errors/error_handler.dart';
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
    final tasksList = ref.watch(homeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final today = ref.watch(todayProvider);
    final isLoading = tasksList.isLoading;

    Future<void> refresh() =>
        ref.read(homeProvider.notifier).refreshTasks(selectedDate);

    return Scaffold(
      drawer: HomeDrawer(),
      appBar: AppBar(
        title: Text(_titleFor(selectedDate, today)),
        actions: [
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(today.year - 5),
                lastDate: DateTime(today.year + 5),
              );
              if (date != null) {
                ref.read(selectedDateProvider.notifier).selectDate(date);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _DateSelector(today: today, selectedDate: selectedDate),
            // Keeps the height stable so the list does not jump.
            SizedBox(
              height: 4,
              child: isLoading && tasksList.value != null
                  ? const LinearProgressIndicator()
                  : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screenHorizontal,
                ),
                child: _buildContent(context, ref, tasksList, refresh),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Task>> tasksList,
    Future<void> Function() refresh,
  ) {
    if (tasksList.hasError && !tasksList.isLoading) {
      return _ErrorView(
        message: ErrorHandler.extractAppError(tasksList.error!).message,
        onRetry: refresh,
      );
    }

    final tasks = tasksList.value;
    if (tasks == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // While another day loads, the tasks shown are not that day's: keep them
    // visible to avoid flicker, but not interactive.
    return IgnorePointer(
      ignoring: tasksList.isLoading,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: tasksList.isLoading ? 0.5 : 1,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: tasks.isEmpty
              ? const _EmptyView()
              : ReorderableListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  onReorderItem: (int oldIndex, int newIndex) async {
                    ref.read(homeProvider.notifier).updateTaskPriorities(
                        oldIndex: oldIndex, newIndex: newIndex);
                  },
                  footer: const SizedBox(
                    height: 75,
                  ),
                  children: [
                    for (final task in tasks)
                      Padding(
                        key: ValueKey(task.id),
                        padding: const EdgeInsets.only(
                          bottom: Spacing.listItemSpacing,
                        ),
                        child: TaskListTile(
                          task: task,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  String _titleFor(DateTime date, DateTime today) {
    if (date == today) return 'Hoy';
    return intl.DateFormat("EEE d 'de' MMM", 'es').format(date);
  }
}

class _DateSelector extends ConsumerWidget {
  final DateTime today;
  final DateTime selectedDate;

  const _DateSelector({required this.today, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = selectableDays(today);
    final colorScheme = Theme.of(context).colorScheme;

    // Seven 48dp chips don't fit on narrow screens or with large text.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...dates.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;

                final currentMonth = intl.DateFormat('MMM', 'es').format(date);

                final previousMonth = index > 0
                    ? intl.DateFormat('MMM', 'es').format(dates[index - 1])
                    : null;

                final shouldShowMonth =
                    index == 0 || currentMonth != previousMonth;

                final isSelected = selectedDate == date;
                final isToday = today == date;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: intl.DateFormat('EEEE d MMMM', 'es').format(date),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).selectDate(date);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs / 2,
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
                        border: isToday
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs,
                        vertical: Spacing.sm,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (shouldShowMonth)
                            Text(
                              currentMonth.toUpperCase(),
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Scrollable so that pull-to-refresh also works here.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: Spacing.xl * 2),
        Icon(Icons.event_available, size: 64, color: colorScheme.outline),
        const SizedBox(height: Spacing.md),
        Text(
          'No hay tareas para este día',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          'Toca + para agregar una',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: Spacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
