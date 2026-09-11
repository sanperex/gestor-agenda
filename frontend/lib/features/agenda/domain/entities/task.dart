/// Estado de una tarea. `apiValue` es el texto exacto que guarda el backend.
enum TaskStatus {
  pending('pending', 'Pendiente'),
  inProgress('inProgress', 'En progreso'),
  completed('completed', 'Completada');

  const TaskStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Si llega un valor desconocido se toma como pendiente, en vez de romper la lista entera.
  static TaskStatus fromApi(String? value) =>
      TaskStatus.values.firstWhere((s) => s.apiValue == value, orElse: () => TaskStatus.pending);
}

enum TaskPriority {
  low('low', 'Baja'),
  medium('medium', 'Media'),
  high('high', 'Alta');

  const TaskPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static TaskPriority fromApi(String? value) =>
      TaskPriority.values.firstWhere((p) => p.apiValue == value, orElse: () => TaskPriority.medium);
}

/// Tarea de la agenda. Clase pura: no sabe nada de JSON, HTTP ni Flutter.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.location,
    required this.status,
    required this.priority,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String location;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? completedAt;

  bool get isCompleted => status == TaskStatus.completed;

  /// Vencida = ya paso la fecha y no se completo. La lista la marca en rojo.
  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());
}
