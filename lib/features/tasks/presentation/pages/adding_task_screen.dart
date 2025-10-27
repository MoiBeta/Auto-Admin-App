import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddingTaskScreen extends ConsumerStatefulWidget {
  const AddingTaskScreen({this.task, super.key});

  final Task? task;

  @override
  ConsumerState<AddingTaskScreen> createState() => _AddingTaskScreenState();
}

class _AddingTaskScreenState extends ConsumerState<AddingTaskScreen> {
  TextEditingController titleEditingController = TextEditingController();
  TextEditingController dateEditingController = TextEditingController();
  TextEditingController reminderEditingController = TextEditingController();

  TaskFrequency taskFrequency = TaskFrequency.daily;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;

  @override
  void initState() {
    if (widget.task != null) {
      Task task = widget.task!;
      titleEditingController.text = task.title;
      selectedDate = task.startDate;
      dateEditingController.text =
          DateFormat('MMM dd yyyy').format(task.startDate);
      taskFrequency = task.taskFrequency;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null ? 'Nueva tarea' : 'Editar tarea',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(hintText: 'Título'),
              controller: titleEditingController,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              child: TextFormField(
                controller: dateEditingController,
                decoration: const InputDecoration(hintText: 'Fecha'),
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
                      setState(() {
                        selectedDate = date;
                        dateEditingController.text =
                            DateFormat('MMM dd yyyy').format(date);
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            GestureDetector(
              child: TextFormField(
                controller: reminderEditingController,
                decoration:
                    const InputDecoration(hintText: 'Hora de recordatorio'),
                enabled: false,
              ),
              onTap: () async {
                bool granted = await ref
                    .read(homeNotifierProvider.notifier)
                    .checkNotificationPermission();
                if (context.mounted) {
                  if (granted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                        reminderEditingController.text = time.format(context);
                      });
                    }
                  } else {
                    showDialog(
                      context: context,
                      builder: (cxt) => AlertDialog(
                        title: Icon(
                          Icons.warning,
                          size: 200,
                        ),
                        content: Text(
                          'Necesitamos tu permiso para mostrar notificaciones de recordatorios',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              context.pop();
                            },
                            child: Text('Ok'),
                          ),
                        ],
                      ),
                    );
                    setState(() {
                      reminderEditingController.clear();
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButton(
              items: TaskFrequency.values.map((TaskFrequency taskFrequency) {
                return DropdownMenuItem(
                  value: taskFrequency,
                  child: Text(
                    getNameFromTaskFrequency(taskFrequency),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              value: taskFrequency,
              style: const TextStyle(color: Colors.black),
              onChanged: (TaskFrequency? value) {
                if (value != null) {
                  setState(() {
                    taskFrequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (titleEditingController.text.isNotEmpty) {
                  final DateTime? reminderDateTime =
                      selectedTime != null ? _combineDateAndTime() : null;

                  if (widget.task == null) {
                    await ref
                        .read(homeNotifierProvider.notifier)
                        .createRecurringTask(
                          title: titleEditingController.text,
                          frequency: taskFrequency,
                          startDate: selectedDate,
                          reminderDate: reminderDateTime,
                        );
                  } else {
                    await ref
                        .read(homeNotifierProvider.notifier)
                        .editRecurringTask(
                          title: titleEditingController.text,
                          frequency: taskFrequency,
                          startDate: selectedDate,
                          reminderDate: reminderDateTime,
                          templateId: widget.task!.templateId,
                          instanceId: widget.task!.instanceId,
                        );
                  }
                }
                if (context.mounted) {
                  context.pop();
                }
              },
              child: ref.watch(homeNotifierProvider).isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      widget.task == null ? 'Agregar' : 'Editar',
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

  DateTime _combineDateAndTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }
}
