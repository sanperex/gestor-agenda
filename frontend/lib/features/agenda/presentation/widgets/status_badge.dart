import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';

/// Colores de estado y prioridad EN UN SOLO LUGAR: si cada pantalla eligiera
/// el suyo, el mismo estado se veria de dos colores y dejaria de significar algo.
class TaskColors {
  TaskColors._();

  static const Color pending = Color(0xFFD97706); // ambar: espera a alguien

  static Color status(TaskStatus s) => switch (s) {
    TaskStatus.pending => pending,
    TaskStatus.inProgress => AppColors.primary,
    TaskStatus.completed => AppColors.success,
  };

  static Color priority(TaskPriority p) => switch (p) {
    TaskPriority.low => AppColors.textSecondary,
    TaskPriority.medium => AppColors.primary,
    TaskPriority.high => AppColors.error,
  };

  static IconData statusIcon(TaskStatus s) => switch (s) {
    TaskStatus.pending => Icons.schedule,
    TaskStatus.inProgress => Icons.autorenew,
    TaskStatus.completed => Icons.check_circle,
  };
}

/// Pastilla con el estado de una tarea.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = TaskColors.status(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // El mismo color con poca opacidad: se lee bien sin mantener otra paleta.
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TaskColors.statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Prioridad como banderita. Va aparte del estado: una tarea puede ser Alta y estar completada.
class PriorityLabel extends StatelessWidget {
  const PriorityLabel({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = TaskColors.priority(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          priority.label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
