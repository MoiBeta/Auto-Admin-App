import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class AddingTaskScreen extends HookConsumerWidget {
  const AddingTaskScreen({this.task, super.key});

  final Task? task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(homeProvider).isLoading;

    // controllers
    final titleEditingController = useTextEditingController();
    final dateEditingController = useTextEditingController();
    final reminderEditingController = useTextEditingController();
    final subtaskController = useTextEditingController();

    // states locales
    final taskFrequency = useState<TaskFrequency>(TaskFrequency.daily);
    final selectedDate = useState<DateTime>(DateTime.now());
    final selectedTime = useState<TimeOfDay?>(null);
    final subtasks = useState<List<String>>([]);

    // init (equivalente a initState)
    useEffect(() {
      if (task != null) {
        final Task t = task!;
        titleEditingController.text = t.title;
        selectedDate.value = t.startDate;
        dateEditingController.text =
            DateFormat('MMM dd yyyy').format(t.startDate);
        taskFrequency.value = t.taskFrequency;
        subtasks.value = [...?t.subtasks?.map((s) => s.title)];
      }
      return null;
    }, const []);

    Future<void> onSave() async {
      if (titleEditingController.text.isEmpty) return;

      DateTime? reminderDateTime;
      if (selectedTime.value != null) {
        reminderDateTime = DateTime(
          selectedDate.value.year,
          selectedDate.value.month,
          selectedDate.value.day,
          selectedTime.value?.hour ?? 0,
          selectedTime.value?.minute ?? 0,
        );
      }

      if (task == null) {
        await ref.read(homeProvider.notifier).createTask(
              title: titleEditingController.text,
              frequency: taskFrequency.value,
              startDate: selectedDate.value,
              reminderDate: reminderDateTime,
              subtasks: subtasks.value,
            );
      } else {
        await ref.read(homeProvider.notifier).editTask(
              title: titleEditingController.text,
              frequency: taskFrequency.value,
              startDate: selectedDate.value,
              reminderDate: reminderDateTime,
              subtasks: subtasks.value,
              taskId: task!.id,
            );
      }

      if (context.mounted) context.pop();
    }

    void addSubTask() {
      final text = subtaskController.text.trim();
      if (text.isNotEmpty) {
        subtasks.value = [...subtasks.value, text];
        subtaskController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(task == null ? 'Nueva tarea' : 'Editar tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(hintText: 'Título'),
                controller: titleEditingController,
              ),
              const SizedBox(height: 10),

              // fecha
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 360)),
                  );
                  if (date != null) {
                    selectedDate.value = date;
                    dateEditingController.text =
                        DateFormat('MMM dd yyyy').format(date);
                  }
                },
                child: TextFormField(
                  controller: dateEditingController,
                  decoration: const InputDecoration(hintText: 'Fecha'),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: () async {
                  final notifier = ref.read(homeProvider.notifier);
                  final granted = await notifier.checkNotificationPermission();

                  if (!context.mounted) return;
                  if (granted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      selectedTime.value = time;
                      if (context.mounted) {
                        reminderEditingController.text = time.format(context);
                      }
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
                    reminderEditingController.clear();
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

              DropdownButton<TaskFrequency>(
                value: taskFrequency.value,
                items: TaskFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(getNameFromTaskFrequency(freq)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) taskFrequency.value = val;
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subtaskController,
                      decoration: const InputDecoration(
                        hintText: 'Agregar subtarea...',
                      ),
                      onSubmitted: (_) => addSubTask(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: addSubTask,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (subtasks.value.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subtasks.value.length,
                  itemBuilder: (context, index) {
                    final subtask = subtasks.value[index];
                    return ListTile(
                      title: Text(subtask),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          subtasks.value = [...subtasks.value..removeAt(index)];
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : onSave,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(task == null ? 'Agregar' : 'Editar'),
              ),
            ],
          ),
        ),
      ),
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
