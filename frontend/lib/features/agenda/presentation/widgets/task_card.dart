import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task.dart';
import '../utils/date_labels.dart';
import 'status_badge.dart';

/// Tarjeta de una tarea en la lista.
/// Recibe callbacks en vez de leer el provider: asi se puede probar y reutilizar sola.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final done = task.isCompleted;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // La franja de color se dibuja como BORDE y no como un Container dentro de un Row con
        // CrossAxisAlignment.stretch: dentro de un ListView la altura es infinita y "stretch"
        // colapsa la tarjeta a cero. Se ve como una lista vacia y no da ningun error.
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: TaskColors.status(task.status), width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 6, 0, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: done, shape: const CircleBorder(), onChanged: (_) => onToggle()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? AppColors.textSecondary : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Wrap y no Row: en un celular angosto los datos bajan de linea en vez de desbordar.
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DueDate(task: task),
                          StatusBadge(status: task.status),
                          PriorityLabel(priority: task.priority),
                          if (task.location.isNotEmpty) _Meta(icon: Icons.place_outlined, text: task.location),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Un menu y no dos botones sueltos: en un celular le quitarian espacio al titulo.
              PopupMenuButton<String>(
                tooltip: 'Acciones',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: AppColors.error),
                      title: Text('Eliminar', style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueDate extends StatelessWidget {
  const _DueDate({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    return _Meta(
      icon: overdue ? Icons.warning_amber_rounded : Icons.event,
      text: dueLabel(task.dueDate),
      color: overdue ? AppColors.error : null,
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
