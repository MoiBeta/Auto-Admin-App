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
  final TextEditingController titleEditingController = TextEditingController();
  final TextEditingController dateEditingController = TextEditingController();
  final TextEditingController reminderEditingController =
      TextEditingController();
  final TextEditingController subtaskController = TextEditingController();

  TaskFrequency taskFrequency = TaskFrequency.daily;
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;

  final List<String> subtasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      final Task task = widget.task!;
      titleEditingController.text = task.title;
      selectedDate = task.startDate;
      dateEditingController.text =
          DateFormat('MMM dd yyyy').format(task.startDate);
      taskFrequency = task.taskFrequency;

      // Si el task tiene subtasks existentes, los agregamos
      subtasks.addAll(task.subtasks?.map((s) => s.title) ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(homeNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nueva tarea' : 'Editar tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Campo título
              TextFormField(
                decoration: const InputDecoration(hintText: 'Título'),
                controller: titleEditingController,
              ),
              const SizedBox(height: 10),

              // Fecha
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 360)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = date;
                      dateEditingController.text =
                          DateFormat('MMM dd yyyy').format(date);
                    });
                  }
                },
                child: TextFormField(
                  controller: dateEditingController,
                  decoration: const InputDecoration(hintText: 'Fecha'),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 10),

              // Hora de recordatorio
              GestureDetector(
                onTap: () async {
                  final notifier = ref.read(homeNotifierProvider.notifier);
                  final granted = await notifier.checkNotificationPermission();

                  if (!context.mounted) return;
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
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Icon(Icons.warning, size: 80),
                        content: const Text(
                          'Necesitamos tu permiso para mostrar notificaciones de recordatorios.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Ok'),
                          ),
                        ],
                      ),
                    );
                    setState(() {
                      reminderEditingController.clear();
                    });
                  }
                },
                child: TextFormField(
                  controller: reminderEditingController,
                  decoration:
                      const InputDecoration(hintText: 'Hora de recordatorio'),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 10),

              // Dropdown frecuencia
              DropdownButton<TaskFrequency>(
                value: taskFrequency,
                items: TaskFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(getNameFromTaskFrequency(freq)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => taskFrequency = val);
                },
              ),
              const SizedBox(height: 20),

              // Subtasks section
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Agregar subtarea...',
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addSubtask,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Lista de subtareas agregadas
              if (subtasks.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.length,
                  itemBuilder: (context, index) {
                    final subtask = subtasks[index];
                    return ListTile(
                      title: Text(subtask),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => subtasks.removeAt(index));
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // Botón principal
              ElevatedButton(
                onPressed: isLoading ? null : _onSavePressed,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(widget.task == null ? 'Agregar' : 'Editar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSubtask() {
    final text = subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        subtasks.add(text);
        subtaskController.clear();
      });
    }
  }

  Future<void> _onSavePressed() async {
    if (titleEditingController.text.isEmpty) return;

    final reminderDateTime =
        selectedTime != null ? _combineDateAndTime() : null;

    if (widget.task == null) {
      await ref.read(homeNotifierProvider.notifier).createRecurringTask(
            title: titleEditingController.text,
            frequency: taskFrequency,
            startDate: selectedDate,
            reminderDate: reminderDateTime,
            subtasks: subtasks,
          );
    } else {
      await ref.read(homeNotifierProvider.notifier).editRecurringTask(
            title: titleEditingController.text,
            frequency: taskFrequency,
            startDate: selectedDate,
            reminderDate: reminderDateTime,
            templateId: widget.task!.templateId,
            instanceId: widget.task!.instanceId,
            subtasks: subtasks,
          );
    }

    if (context.mounted) context.pop();
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime?.hour ?? 0,
      selectedTime?.minute ?? 0,
    );
  }

  String getNameFromTaskFrequency(TaskFrequency freq) {
    switch (freq) {
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
