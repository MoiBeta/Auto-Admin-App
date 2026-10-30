import 'dart:async';

import 'package:auto_admin_app/features/notifications/notification_providers.dart';
import 'package:auto_admin_app/features/tasks/data/enums/task_frequency.dart';
import 'package:auto_admin_app/features/tasks/domain/entities/task.dart';
import 'package:auto_admin_app/features/tasks/presentation/provider/home_provider.dart';
import 'package:auto_admin_app/global/theme/spacing.dart';
import 'package:flutter/foundation.dart';
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
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isSaving = useState(false);

    // controllers
    final titleEditingController = useTextEditingController();
    final dateEditingController = useTextEditingController();
    final reminderEditingController = useTextEditingController();
    final subtaskController = useTextEditingController();

    // Rebuild on typing, to know whether there is something to lose on leaving.
    useListenable(titleEditingController);
    useListenable(subtaskController);

    // states locales
    final taskFrequency = useState<TaskFrequency>(TaskFrequency.daily);
    final selectedDate = useState<DateTime>(ref.read(selectedDateProvider));
    final selectedTime = useState<TimeOfDay?>(null);
    final startDateChanged = useState(false);
    final subtasks = useState<List<String>>([]);

    String formatDate(DateTime date) =>
        DateFormat('d MMM yyyy', 'es').format(date);

    // init (equivalente a initState)
    useEffect(() {
      if (task != null) {
        final Task t = task!;
        titleEditingController.text = t.title;
        selectedDate.value = t.habitStartDate ?? t.startDate;
        taskFrequency.value = t.taskFrequency;
        subtasks.value = [...?t.subtasks?.map((s) => s.title)];
        if (t.reminderDate != null) {
          selectedTime.value = TimeOfDay.fromDateTime(t.reminderDate!);
          // Formatting needs the localizations, available after the first frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && selectedTime.value != null) {
              reminderEditingController.text =
                  selectedTime.value!.format(context);
            }
          });
        }
      }
      dateEditingController.text = formatDate(selectedDate.value);
      return null;
    }, const []);

    final initialTime = task?.reminderDate == null
        ? null
        : TimeOfDay.fromDateTime(task!.reminderDate!);
    final hasChanges = titleEditingController.text != (task?.title ?? '') ||
        subtaskController.text.isNotEmpty ||
        startDateChanged.value ||
        selectedTime.value != initialTime ||
        taskFrequency.value != (task?.taskFrequency ?? TaskFrequency.daily) ||
        !listEquals(
          subtasks.value,
          [...?task?.subtasks?.map((s) => s.title)],
        );

    void addSubTask() {
      final text = subtaskController.text.trim();
      if (text.isNotEmpty) {
        subtasks.value = [...subtasks.value, text];
        subtaskController.clear();
      }
    }

    Future<void> onSave() async {
      if (!formKey.currentState!.validate()) return;
      // Whatever is written in the field is meant to be part of the task.
      addSubTask();
      final title = titleEditingController.text.trim();

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

      isSaving.value = true;
      final messenger = ScaffoldMessenger.of(context);
      final bool saved;
      if (task == null) {
        final created = await ref.read(homeProvider.notifier).createTask(
              title: title,
              frequency: taskFrequency.value,
              startDate: selectedDate.value,
              reminderDate: reminderDateTime,
              subtasks: subtasks.value,
            );
        saved = created != null;
        final home = ref.read(homeProvider);
        if (saved &&
            !home.hasError &&
            home.value?.any((t) => t.id == created.id) == false) {
          final day =
              DateFormat("d 'de' MMMM", 'es').format(selectedDate.value);
          messenger.showSnackBar(
            SnackBar(content: Text('Tarea agregada a partir del $day')),
          );
        }
      } else {
        saved = await ref.read(homeProvider.notifier).editTask(
              title: title,
              frequency: taskFrequency.value,
              startDate: selectedDate.value,
              reminderDate: reminderDateTime,
              removeReminder:
                  task!.reminderDate != null && selectedTime.value == null,
              newStartDate: startDateChanged.value ? selectedDate.value : null,
              subtasks: subtasks.value,
              taskId: task!.id,
            );
      }
      if (!context.mounted) return;

      // On failure keep the form open: the error is reported globally and the
      // user must not lose what they wrote.
      if (saved) {
        context.pop();
      } else {
        isSaving.value = false;
      }
    }

    Future<void> confirmDiscard() async {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Descartar los cambios?'),
          content: const Text('Lo que escribiste no se guardará.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) Navigator.of(context).pop();
    }

    return PopScope(
      canPop: !hasChanges || isSaving.value,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(task == null ? 'Nueva tarea' : 'Editar tarea'),
        ),
        body: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.formHorizontal),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.formHorizontal),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Título'),
                        controller: titleEditingController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Escribe un título'
                            : null,
                      ),
                      const SizedBox(height: Spacing.formFieldSpacing),

                      // fecha
                      TextFormField(
                        controller: dateEditingController,
                        readOnly: true,
                        canRequestFocus: false,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de inicio',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final current = selectedDate.value;
                          final date = await showDatePicker(
                            context: context,
                            initialDate: current,
                            // An existing habit may have started in the past.
                            firstDate:
                                current.isBefore(today) ? current : today,
                            lastDate: [
                              current,
                              today.add(const Duration(days: 360)),
                            ].reduce((a, b) => a.isAfter(b) ? a : b),
                          );
                          if (date != null) {
                            selectedDate.value = date;
                            startDateChanged.value = true;
                            dateEditingController.text = formatDate(date);
                          }
                        },
                      ),
                      const SizedBox(height: Spacing.formFieldSpacing),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: reminderEditingController,
                              readOnly: true,
                              canRequestFocus: false,
                              decoration: const InputDecoration(
                                labelText: 'Hora de recordatorio',
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      selectedTime.value ?? TimeOfDay.now(),
                                );
                                if (time != null) {
                                  selectedTime.value = time;
                                  // Asked here, when its purpose is clear.
                                  unawaited(ref
                                      .read(pushNotificationServiceProvider)
                                      .requestPermission());
                                  if (context.mounted) {
                                    reminderEditingController.text =
                                        time.format(context);
                                  }
                                }
                              },
                            ),
                          ),
                          if (selectedTime.value != null)
                            IconButton(
                              tooltip: 'Quitar recordatorio',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                selectedTime.value = null;
                                reminderEditingController.clear();
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: Spacing.formFieldSpacing),

                      DropdownMenu<TaskFrequency>(
                        initialSelection:
                            task?.taskFrequency ?? taskFrequency.value,
                        expandedInsets: EdgeInsets.zero,
                        label: const Text('Frecuencia'),
                        dropdownMenuEntries:
                            TaskFrequency.supported.map((freq) {
                          return DropdownMenuEntry<TaskFrequency>(
                            value: freq,
                            label: getNameFromTaskFrequency(freq),
                          );
                        }).toList(),
                        onSelected: (val) {
                          if (val != null) taskFrequency.value = val;
                        },
                      ),

                      const SizedBox(height: Spacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: subtaskController,
                              decoration: const InputDecoration(
                                hintText: 'Agregar subtarea...',
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => addSubTask(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Agregar subtarea',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: addSubTask,
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.formFieldSpacing),

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
                                tooltip: 'Eliminar subtarea',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  subtasks.value = [
                                    ...subtasks.value..removeAt(index),
                                  ];
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: Spacing.lg),

                      FilledButton.tonal(
                        onPressed: isSaving.value ? null : onSave,
                        child: isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(task == null ? 'Agregar' : 'Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
