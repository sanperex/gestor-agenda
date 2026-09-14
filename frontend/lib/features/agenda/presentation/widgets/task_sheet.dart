import 'package:flutter/material.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';
import '../../domain/entities/task.dart';
import '../utils/date_labels.dart';
import 'status_badge.dart';

/// Hoja inferior con el detalle de una tarea y sus acciones.
class TaskSheet extends StatelessWidget {
  const TaskSheet({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final done = task.isCompleted;

    return Container(
      decoration: const BoxDecoration(
        color: Vivid.lavender,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Vivid.line, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 16),
            Entrance(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: done ? Vivid.green : Vivid.accentDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.status == TaskStatus.inProgress) ...[
                                const PulseDot(size: 7),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                task.status.label.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PriorityPill(priority: task.priority, onColor: true, showLabelPrefix: true),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 170),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          color: Vivid.accent,
                          icon: Icons.calendar_today_rounded,
                          label: 'Fecha',
                          value: headerDateLabel(task.dueDate),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          color: Vivid.cyan,
                          icon: Icons.schedule_rounded,
                          label: 'Hora',
                          value: timeLabel(task.dueDate),
                        ),
                      ),
                    ],
                  ),
                  if (task.location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      color: Vivid.amber,
                      icon: Icons.place_rounded,
                      label: 'Lugar',
                      value: task.location,
                      horizontal: true,
                    ),
                  ],
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      color: Vivid.green,
                      icon: Icons.check_rounded,
                      label: 'Completada',
                      value: '${headerDateLabel(task.completedAt!)}, ${timeLabel(task.completedAt!)}',
                      horizontal: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Entrance(
              delay: const Duration(milliseconds: 240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SolidButton(
                    color: done ? Vivid.amber : Vivid.green,
                    icon: done ? Icons.undo_rounded : Icons.check_rounded,
                    label: done ? 'Marcar como pendiente' : 'Marcar como completada',
                    onTap: onToggle,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SoftButton(
                          color: Vivid.accent,
                          icon: Icons.edit_rounded,
                          label: 'Editar',
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SoftButton(
                          color: Vivid.red,
                          icon: Icons.delete_outline_rounded,
                          label: 'Eliminar',
                          onTap: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.horizontal = false,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: Vivid.soft(color), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 19),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Vivid.muted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Vivid.ink),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: horizontal
          ? Row(
              children: [
                iconBox,
                const SizedBox(width: 12),
                Expanded(child: texts),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [iconBox, const SizedBox(height: 10), texts],
            ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({required this.color, required this.icon, required this.label, required this.onTap});

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 54,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.color, required this.icon, required this.label, required this.onTap});

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: Vivid.soft(color), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
