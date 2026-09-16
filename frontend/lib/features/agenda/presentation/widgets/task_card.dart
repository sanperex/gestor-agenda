import 'package:flutter/material.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/entities/task.dart';
import '../utils/date_labels.dart';
import 'status_badge.dart';

/// Tarjeta de una tarea en la lista.
/// Recibe callbacks en vez de leer el provider: asi se puede probar y reutilizar sola.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap, required this.onToggle});

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  /// Hoy y mañana ya los dice el título de la sección, asi que ahi basta la hora.
  String get _when {
    final days = daysFromToday(task.dueDate);
    if (!task.isOverdue && (days == 0 || days == 1)) return timeLabel(task.dueDate);
    return dueLabel(task.dueDate);
  }

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted;

    return Pressable(
      onTap: onTap,
      semanticLabel: task.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
        decoration: BoxDecoration(
          color: done ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: done ? const [] : Vivid.card,
        ),
        child: Row(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: done ? 0.6 : 1,
              child: StatusTile(task: task),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: done ? const Color(0xFF9CA3AF) : Vivid.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _when,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: task.isOverdue ? TaskVisuals.overdue : Vivid.muted,
                        ),
                      ),
                      if (!done) PriorityPill(priority: task.priority),
                      if (task.location.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 13, color: Vivid.muted),
                            const SizedBox(width: 2),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                task.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Vivid.muted),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: done ? 'Marcar como pendiente' : 'Completar',
              onPressed: onToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: done
                    ? Container(
                        key: const ValueKey('hecha'),
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: Vivid.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
                      )
                    : Container(
                        key: const ValueKey('pendiente'),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Vivid.line, width: 2.2),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que aparece debajo de la tarjeta al deslizarla: completar hacia la derecha,
/// eliminar hacia la izquierda.
class SwipeBackground extends StatelessWidget {
  const SwipeBackground.complete({super.key, required this.isCompleted}) : _delete = false;
  const SwipeBackground.delete({super.key}) : _delete = true, isCompleted = false;

  final bool _delete;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final label = _delete ? 'Eliminar' : (isCompleted ? 'Pendiente' : 'Completar');
    final icon = _delete ? Icons.delete_outline_rounded : (isCompleted ? Icons.undo_rounded : Icons.check_rounded);
    final color = _delete ? Vivid.red : (isCompleted ? Vivid.amber : Vivid.green);

    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: _delete ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
