import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
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

  void _toggleSubtaskCompletion(Subtask subtask) {
    ref.read(homeProvider.notifier).toggleSubtask(
        task: widget.task,
        subtask: subtask,
        date: ref.read(selectedDateProvider));
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final hasSubtasks = (task.subtasks?.isNotEmpty ?? false);

    return Semantics(
      label: '${task.title}, ${task.completed ? "completada" : "pendiente"}',
      child: Card(
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
                  : () => ref.read(homeProvider.notifier).toggleTask(
                      task: task, date: ref.read(selectedDateProvider)),
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
                      child: InkResponse(
                        onTap: hasSubtasks
                            ? null
                            : () => ref.read(homeProvider.notifier).toggleTask(
                                task: task,
                                date: ref.read(selectedDateProvider)),
                        child: Icon(
                          task.completed
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: task.completed
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    decoration: task.completed
                                        ? TextDecoration.lineThrough
                                        : null,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    MenuAnchor(
                      menuChildren: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Editar'),
                          onTap: () {
                            context.pushNamed(
                              Routes.addingTask,
                              extra: task,
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Borrar'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Icon(Icons.warning, size: 80),
                                content:
                                    const Text('¿Quieres eliminar esta tarea?'),
                                actions: [
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(ctx).colorScheme.error,
                                      foregroundColor:
                                          Theme.of(ctx).colorScheme.onError,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(homeProvider.notifier)
                                          .deleteTask(
                                            taskId: task.id,
                                            scope: DeleteScope.all,
                                          );
                                      if (ctx.mounted) ctx.pop();
                                    },
                                    child: const Text('Sí, eliminar'),
                                  ),
                                  TextButton(
                                    onPressed: () => ctx.pop(),
                                    child: const Text('No'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      builder: (context, controller, child) {
                        return SizedBox(
                          width: 48,
                          height: 48,
                          child: GestureDetector(
                            onTap: () {
                              controller.isOpen
                                  ? controller.close()
                                  : controller.open();
                            },
                            child: Center(child: child),
                          ),
                        );
                      },
                      child: const Icon(Icons.more_vert),
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
                padding: const EdgeInsets.only(
                    left: 45, right: 12, bottom: 8, top: 4),
                child: Column(
                  children: task.subtasks?.map((subtask) {
                        return ListTile(
                          onTap: () => _toggleSubtaskCompletion(subtask),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconButton(
                            icon: Icon(
                              subtask.completed
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: subtask.completed
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            onPressed: () => _toggleSubtaskCompletion(subtask),
                          ),
                          title: Text(
                            subtask.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  decoration: subtask.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
