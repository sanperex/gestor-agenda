import 'package:flutter/material.dart';

import '../../../../core/theme/vivid.dart';
import '../../domain/entities/task.dart';

/// Color e icono de cada estado EN UN SOLO LUGAR: si cada pantalla eligiera el suyo,
/// el mismo estado se veria de dos colores y dejaria de significar algo.
class TaskVisuals {
  const TaskVisuals._(this.color, this.icon);

  final Color color;
  final IconData icon;

  static const Color overdue = Vivid.red;
  static const Color pending = Vivid.amber;
  static const Color done = Vivid.green;

  /// La vencida gana sobre el estado: una tarea pendiente que ya paso de fecha
  /// necesita otra señal que una que todavia esta a tiempo.
  static TaskVisuals of(Task task) {
    if (task.isOverdue) return const TaskVisuals._(overdue, Icons.priority_high_rounded);
    return forStatus(task.status);
  }

  static TaskVisuals forStatus(TaskStatus status) => switch (status) {
    TaskStatus.pending => const TaskVisuals._(pending, Icons.schedule_rounded),
    TaskStatus.inProgress => const TaskVisuals._(Vivid.accent, Icons.bolt_rounded),
    TaskStatus.completed => const TaskVisuals._(done, Icons.check_rounded),
  };

  static Color priorityColor(TaskPriority p) => switch (p) {
    TaskPriority.low => Vivid.muted,
    TaskPriority.medium => Vivid.accent,
    TaskPriority.high => overdue,
  };
}

/// Cuadro con el icono del estado sobre un fondo suave de su color, al inicio de cada tarjeta.
class StatusTile extends StatelessWidget {
  const StatusTile({super.key, required this.task, this.size = 46});

  final Task task;
  final double size;

  @override
  Widget build(BuildContext context) {
    final v = TaskVisuals.of(task);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Vivid.soft(v.color), borderRadius: BorderRadius.circular(size / 3)),
      child: Icon(v.icon, color: v.color, size: size * 0.5),
    );
  }
}

/// Pastilla con el estado de una tarea.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.onColor = false});

  final TaskStatus status;

  /// true cuando va sobre un fondo de color (el banner del detalle).
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final color = TaskVisuals.forStatus(status).color;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onColor ? Colors.white.withValues(alpha: 0.16) : Vivid.soft(color),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: onColor ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Pastilla de prioridad. Va aparte del estado: una tarea puede ser Alta y estar completada.
class PriorityPill extends StatelessWidget {
  const PriorityPill({super.key, required this.priority, this.onColor = false, this.showLabelPrefix = false});

  final TaskPriority priority;
  final bool onColor;
  final bool showLabelPrefix;

  @override
  Widget build(BuildContext context) {
    final color = onColor ? Colors.white : TaskVisuals.priorityColor(priority);
    final text = showLabelPrefix ? 'Prioridad ${priority.label.toLowerCase()}' : priority.label;
    return Container(
      height: onColor ? 28 : 22,
      padding: EdgeInsets.symmetric(horizontal: onColor ? 12 : 9),
      decoration: BoxDecoration(
        color: onColor ? Colors.white.withValues(alpha: 0.16) : Vivid.soft(color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: onColor ? 13 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
