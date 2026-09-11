import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../../domain/entities/task_summary.dart';

/// Version de [Task] que sabe leerse desde el JSON de la API.
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.dueDate,
    required super.location,
    required super.status,
    required super.priority,
    super.completedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      // La API guarda en UTC; se pasa a la hora del telefono para mostrarla.
      dueDate: DateTime.parse(json['dueDate'] as String).toLocal(),
      location: json['location'] as String? ?? '',
      status: TaskStatus.fromApi(json['status'] as String?),
      priority: TaskPriority.fromApi(json['priority'] as String?),
      completedAt: json['completedAt'] == null ? null : DateTime.parse(json['completedAt'] as String).toLocal(),
    );
  }

  /// Cuerpo de POST y PUT. Sin id ni userId (ver [TaskInput]).
  static Map<String, dynamic> inputToJson(TaskInput input) {
    return {
      'title': input.title,
      'description': input.description,
      // En UTC para que la hora no cambie de significado segun la zona del telefono.
      'dueDate': input.dueDate.toUtc().toIso8601String(),
      'location': input.location,
      'status': input.status.apiValue,
      'priority': input.priority.apiValue,
    };
  }

  static TaskSummary summaryFromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return TaskSummary(
      total: read('total'),
      pending: read('pending'),
      inProgress: read('inProgress'),
      completed: read('completed'),
    );
  }
}
