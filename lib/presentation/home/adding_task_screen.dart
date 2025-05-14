import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/state/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddingTaskScreen extends ConsumerStatefulWidget {
  const AddingTaskScreen({super.key});

  @override
  ConsumerState<AddingTaskScreen> createState() => _AddingTaskScreenState();
}

class _AddingTaskScreenState extends ConsumerState<AddingTaskScreen> {
  TextEditingController titleEditingController = TextEditingController();
  TextEditingController dateEditingController = TextEditingController();
  TaskFrequency taskFrequency = TaskFrequency.daily;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva tarea'),
      ),
      body: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(hintText: 'Titulo'),
            controller: titleEditingController,
          ),
          GestureDetector(
            child: TextFormField(
              controller: dateEditingController,
              decoration: InputDecoration(hintText: 'Fecha'),
              enabled: false,
            ),
            onTap: () {
              showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 360)),
              ).then(
                    (date) {
                  if (date != null) {
                    setState(
                          () {
                        selectedDate = date;
                        dateEditingController.text =
                            DateFormat('MMM dd yyyy').format(date);
                      },
                    );
                  }
                },
              );
            },
          ),
          DropdownButton(
            items: TaskFrequency.values.map((TaskFrequency taskFrequency) {
              return DropdownMenuItem(
                value: taskFrequency,
                child: Text(
                    getNameFromTaskFrequency(taskFrequency),
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            value: taskFrequency,
            style: TextStyle(
              color: Colors.black,
            ),
            onChanged: (TaskFrequency? value) {
              if (value != null) {
                setState(() {
                  taskFrequency = value;
                });
              }
            },
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleEditingController.text.isNotEmpty){
                await ref.read(homeNotifierProvider.notifier).createRecurringTask(
                  title: titleEditingController.text,
                  frequency: taskFrequency,
                  startDate: selectedDate,
                );
              }
              if(context.mounted){
                context.pop();
              }
            },
            child: ref.watch(isLoadingProvider)
                ? CircularProgressIndicator()
                : Text('Agregar'),
          ),
        ],
      ),
    );
  }

  String getNameFromTaskFrequency(TaskFrequency taskFrequency){
    switch(taskFrequency){
      case TaskFrequency.none:
        return 'Ninguno';
      case TaskFrequency.daily:
        return 'Diariamente';
      case TaskFrequency.weekly:
        return 'Semanalmente';
      case TaskFrequency.monthly:
        return 'Mensualmente';
      case TaskFrequency.yearly:
        return 'Anualmente';
      case TaskFrequency.custom:
        return 'Personalizado';
    }
  }
}
