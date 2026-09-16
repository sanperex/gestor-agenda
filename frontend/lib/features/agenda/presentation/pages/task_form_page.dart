import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/vivid_backdrop.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../providers/task_provider.dart';
import '../utils/date_labels.dart';
import '../widgets/status_badge.dart';

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

  void _setDay(DateTime day) {
    setState(() => _dueDate = DateTime(day.year, day.month, day.day, _dueDate.hour, _dueDate.minute));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      // Se permite el pasado: sirve para anotar algo que ya paso y no se registro.
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) _setDay(picked);
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Vivid.lavender,
        // StackFit.expand: sin esto el Stack mide lo que el formulario, y en una pantalla alta
        // el botón de guardar queda a media pantalla en vez de pegado abajo.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Form(
              key: _formKey,
              // SingleChildScrollView y no ListView: ListView solo construye lo que se ve, y un
              // campo fuera de pantalla se desmonta y validate() ya no lo revisa.
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 110 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(isSaving),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Entrance(delay: const Duration(milliseconds: 60), child: _when(isSaving)),
                          const SizedBox(height: 20),
                          Entrance(delay: const Duration(milliseconds: 110), child: _priorityPicker(isSaving)),
                          const SizedBox(height: 20),
                          Entrance(delay: const Duration(milliseconds: 160), child: _statusPicker(isSaving)),
                          const SizedBox(height: 20),
                          Entrance(delay: const Duration(milliseconds: 210), child: _locationField(isSaving)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Vivid.lavender.withValues(alpha: 0), Vivid.lavender],
                    stops: const [0, 0.35],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomInset),
                  child: Pressable(
                    onTap: isSaving ? null : _save,
                    semanticLabel: widget.isEditing ? 'Guardar cambios' : 'Crear tarea',
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSaving ? Vivid.accent.withValues(alpha: 0.6) : Vivid.accent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, color: Colors.white, size: 21),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isEditing ? 'Guardar cambios' : 'Crear tarea',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isSaving) {
    final top = MediaQuery.of(context).padding.top;
    const none = InputBorder.none;

    return Stack(
      children: [
        // Termina 2 px antes del borde para que no asome una línea bajo la hoja lavanda.
        const Positioned.fill(bottom: 2, child: VividBackdrop()),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Vivid.lavender,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 21),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      fixedSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isEditing ? 'Editar tarea' : 'Nueva tarea',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Entrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¿QUÉ TIENES QUE HACER?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      key: const ValueKey('task-title'),
                      controller: _title,
                      enabled: !isSaving,
                      maxLength: 100,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      cursorColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe el título',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: none,
                        enabledBorder: none,
                        focusedBorder: none,
                        errorBorder: none,
                        focusedErrorBorder: none,
                        disabledBorder: none,
                        counterText: '',
                        errorStyle: const TextStyle(
                          color: Color(0xFFFFE1E1),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
                    ),
                    TextFormField(
                      key: const ValueKey('task-description'),
                      controller: _description,
                      enabled: !isSaving,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: Colors.white,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.4),
                      decoration: InputDecoration(
                        hintText: 'Añade una descripción (opcional)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: none,
                        enabledBorder: none,
                        focusedBorder: none,
                        disabledBorder: none,
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _when(bool isSaving) {
    final today = DateTime.now();
    final days = List.generate(5, (i) => DateTime(today.year, today.month, today.day + i));
    final selectedIndex = days.indexWhere((d) => daysFromToday(_dueDate, now: d) == 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Cuándo'),
        Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              Expanded(
                child: _DayPill(
                  top: weekdayShort(days[i]),
                  day: '${days[i].day}',
                  bottom: i == 0 ? 'Hoy' : null,
                  selected: i == selectedIndex,
                  onTap: isSaving ? null : () => _setDay(days[i]),
                ),
              ),
              const SizedBox(width: 6),
            ],
            // Cualquier otra fecha: si la elegida no está entre los cinco días, se muestra aquí.
            Expanded(
              child: _DayPill(
                top: selectedIndex == -1 ? weekdayShort(_dueDate) : 'OTRA',
                day: selectedIndex == -1 ? '${_dueDate.day}' : null,
                bottom: selectedIndex == -1 ? shortDateLabel(_dueDate).split(' ').last : null,
                icon: Icons.calendar_month_rounded,
                selected: selectedIndex == -1,
                tooltip: 'Elegir otra fecha',
                onTap: isSaving ? null : _pickDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Pressable(
          onTap: isSaving ? null : _pickTime,
          semanticLabel: 'Cambiar hora',
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: Vivid.soft(Vivid.cyan), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.schedule_rounded, size: 18, color: Vivid.cyan),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // Fecha corta: el día completo ya se ve en las pastillas de arriba.
                    '${shortDateLabel(_dueDate)} · ${timeLabel(_dueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Vivid.ink),
                  ),
                ),
                const Text(
                  'Cambiar hora',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Vivid.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _priorityPicker(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Prioridad'),
        Row(
          children: [
            for (final p in TaskPriority.values) ...[
              Expanded(
                child: _ChoicePill(
                  label: p.label,
                  color: TaskVisuals.priorityColor(p),
                  selected: _priority == p,
                  onTap: isSaving ? null : () => setState(() => _priority = p),
                ),
              ),
              if (p != TaskPriority.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _statusPicker(bool isSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Estado'),
        Row(
          children: [
            for (final s in TaskStatus.values) ...[
              Expanded(
                child: _ChoicePill(
                  label: s.label,
                  color: TaskVisuals.forStatus(s).color,
                  selected: _status == s,
                  onTap: isSaving ? null : () => setState(() => _status = s),
                ),
              ),
              if (s != TaskStatus.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _locationField(bool isSaving) {
    final radius = BorderRadius.circular(16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('Ubicación'),
        TextFormField(
          key: const ValueKey('task-location'),
          controller: _location,
          enabled: !isSaving,
          maxLength: 100,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Vivid.ink),
          decoration: InputDecoration(
            hintText: 'Opcional, por ejemplo Ambiente 3',
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            prefixIcon: const Icon(Icons.place_rounded, color: Vivid.amber),
            border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: Vivid.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Vivid.ink),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.top,
    required this.selected,
    required this.onTap,
    this.day,
    this.bottom,
    this.icon,
    this.tooltip,
  });

  final String top;
  final String? day;
  final String? bottom;
  final IconData? icon;
  final bool selected;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Vivid.ink;
    final pill = Pressable(
      onTap: onTap,
      semanticLabel: tooltip ?? '$top $day',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 70,
        decoration: BoxDecoration(
          color: selected ? Vivid.accent : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              top,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: selected ? Colors.white.withValues(alpha: 0.8) : Vivid.muted,
              ),
            ),
            const SizedBox(height: 2),
            if (day != null)
              Text(
                day!,
                style: TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w800, color: fg),
              )
            else
              Icon(icon, size: 20, color: Vivid.accent),
            if (bottom != null)
              Text(
                bottom!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white.withValues(alpha: 0.8) : Vivid.muted,
                ),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label, required this.color, required this.selected, required this.onTap});

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(color: selected ? color : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!selected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : Vivid.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
