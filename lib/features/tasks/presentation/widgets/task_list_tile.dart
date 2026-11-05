import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/theme/forge_palette.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:auto_admin_app/global/widgets/forge/ember_burst.dart';
import 'package:auto_admin_app/global/widgets/forge/flame_edge.dart';
import 'package:auto_admin_app/global/widgets/forge/forge_completion_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListTile extends ConsumerStatefulWidget {
  final Task task;

  const TaskListTile({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<TaskListTile> createState() => _TaskListTileState();
}

class _TaskListTileState extends ConsumerState<TaskListTile> {
  bool _expanded = false;

  /// The tile outlives a change of day, when `completed` changes too: only a
  /// change caused by a touch in this tile is forged.
  bool _touched = false;
  bool _animateCompletion = false;

  @override
  void didUpdateWidget(TaskListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.task, widget.task)) return;
    _animateCompletion = _touched;
    _touched = false;
  }

  void _toggleTaskCompletion() {
    _touched = true;
    ref
        .read(homeProvider.notifier)
        .toggleTask(task: widget.task, date: ref.read(selectedDateProvider));
  }

  void _toggleSubtaskCompletion(Subtask subtask) {
    _touched = true;
    ref.read(homeProvider.notifier).toggleSubtask(
        task: widget.task,
        subtask: subtask,
        date: ref.read(selectedDateProvider));
  }

  void _delete() {
    final notifier = ref.read(homeProvider.notifier);
    notifier.scheduleDelete(widget.task);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${widget.task.title}" eliminada'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          // Must close before the delete is sent, even with an action.
          persist: false,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => notifier.undoDelete(widget.task.id),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final subtasks = task.subtasks ?? [];
    final completedSubtasks = subtasks.where((s) => s.completed).length;

    return Semantics(
      label: [
        task.title,
        task.completed ? 'completada' : 'pendiente',
        if (subtasks.isNotEmpty)
          '$completedSubtasks de ${subtasks.length} subtareas',
      ].join(', '),
      expanded: subtasks.isNotEmpty ? _expanded : null,
      child: ForgeCompletionAnimation(
        forged: task.completed,
        animate: _animateCompletion,
        cardBuilder: (context, look) => Theme(
          data: look.applyTo(Theme.of(context)),
          child: Builder(builder: (context) => _buildCard(context, look)),
        ),
        effectBuilder: (context, sweep) => Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            FlameEdge(sweep: sweep),
            const EmberBurst(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, ForgeLook look) {
    final task = widget.task;
    // The layer under the sweep still shows the task as it was.
    final completed = look != ForgeLook.pending;
    final subtasks = task.subtasks ?? [];
    final hasSubtasks = subtasks.isNotEmpty;
    final completedSubtasks = subtasks.where((s) => s.completed).length;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: look.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: hasSubtasks
                ? () => setState(() => _expanded = !_expanded)
                : _toggleTaskCompletion,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.cardInternalHorizontal,
                vertical: Spacing.cardInternalVertical,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: hasSubtasks
                        // Completed through its subtasks: progress instead of
                        // a checkbox that would do nothing.
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: completedSubtasks / subtasks.length,
                                  strokeWidth: 3,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              Text(
                                '$completedSubtasks/${subtasks.length}',
                                style: textTheme.labelSmall,
                              ),
                            ],
                          )
                        : InkResponse(
                            onTap: _toggleTaskCompletion,
                            child: Icon(
                              completed
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: completed ? colorScheme.primary : null,
                            ),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: textTheme.titleMedium!.copyWith(
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                        ),
                        child: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (hasSubtasks)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.edit),
                        onPressed: () {
                          context.pushNamed(
                            Routes.addingTask,
                            extra: task,
                          );
                        },
                        child: const Text('Editar'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.delete),
                        onPressed: _delete,
                        child: const Text('Borrar'),
                      ),
                    ],
                    builder: (context, controller, child) {
                      return IconButton(
                        tooltip: 'Más opciones',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          controller.isOpen
                              ? controller.close()
                              : controller.open();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Subtasks expandibles
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded && hasSubtasks
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.only(left: 45, right: 12, bottom: 8, top: 4),
              child: Column(
                children: subtasks.map((subtask) {
                  return Semantics(
                    checked: subtask.completed,
                    child: ListTile(
                      onTap: () => _toggleSubtaskCompletion(subtask),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        subtask.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: subtask.completed
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        subtask.title,
                        style: textTheme.bodyMedium?.copyWith(
                          decoration: subtask.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
