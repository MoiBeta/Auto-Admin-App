import 'package:auto_admin_app/features/tasks/data/models/task_instance.dart';
import 'package:auto_admin_app/data/models/task_template.dart';
import 'package:auto_admin_app/router/routes.dart';
import 'package:auto_admin_app/features/home/presentation/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListTile extends ConsumerWidget {
  final TaskInstance task;

  const TaskListTile({
    required this.task,
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return InkWell(
      onTap: () {
        ref.read(homeNotifierProvider.notifier).completeTask(
              taskInstanceId: task.id,
              completed: !task.completed,
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
        child: FutureBuilder<TaskTemplate?>(
          future: ref
              .read(homeNotifierProvider.notifier)
              .getTaskTemplateFromId(task.taskTemplateId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              TaskTemplate taskTemplate = snapshot.data!;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    task.completed
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        taskTemplate.title,
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
                            extra: snapshot.data,
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
                                  content:
                                      Text('¿Quieres eliminar esta tarea?'),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        await ref
                                            .read(homeNotifierProvider.notifier)
                                            .deleteRecurringTask(
                                                task.taskTemplateId);
                                        if (context.mounted) {
                                          context.pop();
                                        }
                                      },
                                      child: Text('Si, Eliminar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        context.pop();
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
              );
            }

            return Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
}
