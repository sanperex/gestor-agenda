import 'task.dart';

/// Datos que el usuario llena en el formulario (crear o editar).
/// No lleva id ni userId: el id lo pone MongoDB y el userId sale del token.
class TaskInput {
  const TaskInput({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.location,
    required this.status,
    required this.priority,
  });

  final String title;
  final String description;
  final DateTime dueDate;
  final String location;
  final TaskStatus status;
  final TaskPriority priority;
}
