import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/domain/enums/delete_scope.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListTile extends ConsumerWidget {
  final Task task;

  const TaskListTile({
    super.key,
    required this.task,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return InkWell(
      onTap: () {
        ref.read(homeNotifierProvider.notifier).completeTask(
              task: task,
            );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(50),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 10,
        ),
        margin: EdgeInsets.only(
          bottom: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              task.completed ? Icons.check_box : Icons.check_box_outline_blank,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            MenuAnchor(
              menuChildren: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar'),
                  onTap: () {
                    context.pushNamed(
                      Routes.addingTask,
                      extra: task,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Borrar'),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Icon(
                              Icons.warning,
                              size: 100,
                            ),
                            content: Text('¿Quieres eliminar esta tarea?'),
                            actions: [
                              ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(homeNotifierProvider.notifier)
                                      .deleteRecurringTask(
                                        templateId: task.templateId,
                                        scope: DeleteScope.all,
                                        instanceId: task.instanceId,
                                      );
                                  if (ctx.mounted) {
                                    ctx.pop();
                                  }
                                },
                                child: Text('Si, Eliminar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ctx.pop();
                                },
                                child: Text('No'),
                              ),
                            ],
                          );
                        });
                  },
                ),
              ],
              builder: (BuildContext context, MenuController controller,
                  Widget? child) {
                return GestureDetector(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: child,
                );
              },
              child: Icon(
                Icons.more_vert,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
