import 'package:auto_admin_app/data/enums/task_frequency.dart';
import 'package:auto_admin_app/data/models/task_template.dart';
import 'package:auto_admin_app/state/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddingTaskScreen extends ConsumerStatefulWidget {
  const AddingTaskScreen({this.taskTemplate, super.key});

  final TaskTemplate? taskTemplate;

  @override
  ConsumerState<AddingTaskScreen> createState() => _AddingTaskScreenState();
}

class _AddingTaskScreenState extends ConsumerState<AddingTaskScreen> {
  TextEditingController titleEditingController = TextEditingController();
  TextEditingController dateEditingController = TextEditingController();
  TaskFrequency taskFrequency = TaskFrequency.daily;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    if (widget.taskTemplate != null) {
      TaskTemplate taskTemplate = widget.taskTemplate!;
      titleEditingController.text = taskTemplate.title;
      selectedDate = taskTemplate.startDate;
      dateEditingController.text =
          DateFormat('MMM dd yyyy').format(taskTemplate.startDate);
      taskFrequency = taskTemplate.frequency;
    }
    super.initState();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskTemplate == null ? 'Nueva tarea' : 'Editar tarea',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(hintText: 'Titulo'),
              controller: titleEditingController,
            ),
            const SizedBox(
              height: 10,
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
                if (titleEditingController.text.isNotEmpty) {
                  await ref
                      .read(homeNotifierProvider.notifier)
                      .createEditRecurringTask(
                        taskTemplateId: widget.taskTemplate?.id,
                        title: titleEditingController.text,
                        frequency: taskFrequency,
                        startDate: selectedDate,
                        mustUpdate: widget.taskTemplate?.id != null,
                      );
                }
                if (context.mounted) {
                  context.pop();
                }
              },
              child: ref.watch(isLoadingProvider)
                  ? CircularProgressIndicator()
                  : Text(
                      widget.taskTemplate == null ? 'Agregar' : 'Editar',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String getNameFromTaskFrequency(TaskFrequency taskFrequency) {
    switch (taskFrequency) {
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
