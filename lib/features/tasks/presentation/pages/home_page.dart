import 'package:auto_admin_app/core/constants/routes.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/home_drawer.dart';
import 'package:auto_admin_app/features/tasks/presentation/widgets/task_list_tile.dart';
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
                      /* ref
                          .read(homeNotifierProvider.notifier)
                          .updateTaskPriorities(oldIndex, newIndex);*/
                    },
                    children: [
                      ...data.asMap().entries.map(
                            (entry) => TaskListTile(
                              task: entry.value,
                              key: ValueKey('${entry.value.id}_${entry.key}'),
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
