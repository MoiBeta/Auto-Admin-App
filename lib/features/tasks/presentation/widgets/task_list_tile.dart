import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/sub_task.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
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
    final notifier = ref.read(homeProvider.notifier);
    notifier.toggleSubtaskCompletion(task: widget.task, subtask: subtask);

    // Si todos los subtasks están completos → marcar el task principal
    final allCompleted =
        widget.task.subtasks?.every((s) => s.completed) ?? false;
    if (allCompleted && !widget.task.completed) {
      notifier.completeTask(task: widget.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final hasSubtasks = (task.subtasks?.isNotEmpty ?? false);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: hasSubtasks
                ? () => setState(() => _expanded = !_expanded)
                : () =>
                    ref.read(homeProvider.notifier).completeTask(task: task),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    task.completed
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: task.completed ? Colors.green : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (hasSubtasks)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[700],
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
                                ElevatedButton(
                                  onPressed: () async {
                                    await ref
                                        .read(homeProvider.notifier)
                                        .deleteRecurringTask(
                                          templateId: task.templateId,
                                          scope: DeleteScope.all,
                                          instanceId: task.instanceId,
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
                      return GestureDetector(
                        onTap: () {
                          controller.isOpen
                              ? controller.close()
                              : controller.open();
                        },
                        child: child,
                      );
                    },
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ),

          // Subtasks expandibles
          if (_expanded && hasSubtasks)
            Padding(
              padding:
                  const EdgeInsets.only(left: 45, right: 12, bottom: 8, top: 4),
              child: Column(
                children: task.subtasks!.map((subtask) {
                  return ListTile(
                    onTap: () => _toggleSubtaskCompletion(subtask),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(
                      icon: Icon(
                        subtask.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            subtask.completed ? Colors.green : Colors.grey[600],
                      ),
                      onPressed: () => _toggleSubtaskCompletion(subtask),
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: subtask.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
