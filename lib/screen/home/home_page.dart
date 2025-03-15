import 'package:auto_admin_app/core/models/task_instance.dart';
import 'package:auto_admin_app/core/models/task_template.dart';
import 'package:auto_admin_app/router/routes.dart';
import 'package:auto_admin_app/screen/home/home_provider.dart';
import 'package:auto_admin_app/screen/home/widget/home_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    List<TaskInstance> tasksList = ref.watch(homeNotifierProvider);
    DateTime selectedDate = ref.watch(selectedDateProvider);
    return Scaffold(
      drawer: HomeDrawer(),
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...getDateTimeRange().map(
                (date) => GestureDetector(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).selectDate(date);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(5),
                      border: selectedDate.month == date.month &&
                              selectedDate.day == date.day
                          ? Border.all(
                              width: 2,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('dd').format(date),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ReorderableListView(
                onReorder: (int oldIndex, int newIndex) async {
                  ref.read(homeNotifierProvider.notifier).updateTaskPriorities(oldIndex, newIndex);
                },
                children: [
                  ...tasksList.map(
                      (task) => InkWell(
                        key: ValueKey(task.id),
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
                          ),
                          margin: EdgeInsets.only(
                            bottom: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(
                                task.completed
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                              ),
                              FutureBuilder(
                                future: ref
                                    .read(homeNotifierProvider.notifier)
                                    .getTaskTemplateFromId(task.taskTemplateId),
                                builder: (context,
                                    AsyncSnapshot<TaskTemplate?> snapshot) {
                                  if (snapshot.hasData) {
                                    TaskTemplate taskTemplate = snapshot.data!;
                                    return Text(taskTemplate.title);
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: Icon(
                                          Icons.warning,
                                          size: 100,
                                        ),
                                        content: Text(
                                            '¿Quieres eliminar esta tarea?'),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              await ref
                                                  .read(homeNotifierProvider
                                                      .notifier)
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
                                    },
                                  );
                                },
                                icon: Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
              ),
            ),],
          ),
      floatingActionButton: FloatingActionButton(
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
