import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/snackbar.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../providers/task_provider.dart';
import '../utils/date_labels.dart';

/// Formulario de tarea (Aprendiz B). La MISMA pantalla crea y edita:
/// si [task] es null es una tarea nueva; si trae una, se edita esa.
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.task});

  final Task? task;

  bool get isEditing => task != null;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late DateTime _dueDate;
  late TaskStatus _status;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _location = TextEditingController(text: t?.location ?? '');
    // Una tarea nueva arranca en la proxima hora en punto: casi siempre se deja asi,
    // y ahorra abrir dos selectores para algo de hoy.
    _dueDate = t?.dueDate ?? _nextHour();
    _status = t?.status ?? TaskStatus.pending;
    _priority = t?.priority ?? TaskPriority.medium;
  }

  static DateTime _nextHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      // Se permite el pasado: sirve para anotar algo que ya paso y no se registro.
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dueDate = DateTime(picked.year, picked.month, picked.day, _dueDate.hour, _dueDate.minute));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDate));
    if (picked == null) return;
    setState(() => _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, picked.hour, picked.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final input = TaskInput(
      title: _title.text.trim(),
      description: _description.text.trim(),
      dueDate: _dueDate,
      location: _location.text.trim(),
      status: _status,
      priority: _priority,
    );

    final ok = widget.isEditing ? await provider.update(widget.task!.id, input) : await provider.create(input);

    // Se cierra SOLO si el servidor acepto: si fallo, el usuario sigue con lo que escribio
    // en pantalla en vez de perderlo.
    if (ok) {
      showMessage(messenger, widget.isEditing ? 'Tarea actualizada' : 'Tarea creada');
      navigator.pop();
    } else {
      showMessage(messenger, provider.errorMessage ?? 'No se pudo guardar', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select<TaskProvider, bool>((p) => p.isSaving);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Editar tarea' : 'Nueva tarea')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // SingleChildScrollView y no ListView: ListView solo construye lo que se ve, y un
          // campo fuera de pantalla se desmonta y validate() ya no lo revisa. Un titulo vacio
          // llegaria al servidor si el usuario bajo hasta el boton antes de guardar.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  enabled: !isSaving,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.title)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _description,
                  enabled: !isSaving,
                  maxLength: 500,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Fecha y hora', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: isSaving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(dueLabel(_dueDate).split(',').first, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: isSaving ? null : _pickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(timeLabel(_dueDate)),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(longDateLabel(_dueDate), style: Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _location,
                  enabled: !isSaving,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación (opcional)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Prioridad', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: [for (final p in TaskPriority.values) ButtonSegment(value: p, label: Text(p.label))],
                  selected: {_priority},
                  showSelectedIcon: false,
                  onSelectionChanged: isSaving ? null : (s) => setState(() => _priority = s.first),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Estado', prefixIcon: Icon(Icons.flag_outlined)),
                  items: [for (final s in TaskStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
                  onChanged: isSaving ? null : (s) => setState(() => _status = s ?? _status),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isSaving ? null : _save,
                  child: isSaving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(widget.isEditing ? 'Guardar cambios' : 'Crear tarea'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
