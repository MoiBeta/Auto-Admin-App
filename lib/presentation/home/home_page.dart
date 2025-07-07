import 'package:auto_admin_app/data/models/task_instance.dart';
import 'package:auto_admin_app/presentation/home/widget/task_list_tile.dart';
import 'package:auto_admin_app/router/routes.dart';
import 'package:auto_admin_app/state/home_provider.dart';
import 'package:auto_admin_app/presentation/home/widget/home_drawer.dart';
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
    AsyncValue<List<TaskInstance>> tasksList = ref.watch(homeNotifierProvider);
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
                          intl.DateFormat('dd').format(date),
                        ),
                        Text(
                          intl.DateFormat('MMM').format(date),
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
              child: tasksList.when(
                data: (data) => ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) async {
                    ref
                        .read(homeNotifierProvider.notifier)
                        .updateTaskPriorities(oldIndex, newIndex);
                  },
                  children: [
                    ...data.map(
                      (TaskInstance task) => TaskListTile(
                        task: task,
                        key: ValueKey(task.id),
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
