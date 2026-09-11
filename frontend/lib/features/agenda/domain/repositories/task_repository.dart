import '../entities/task.dart';
import '../entities/task_input.dart';
import '../entities/task_summary.dart';

/// Contrato: QUE se puede hacer con las tareas, sin decir COMO.
/// La implementacion real (API) esta en data/repositories.
abstract class TaskRepository {
  /// Filtro por estado y busqueda por texto, opcionales y combinables.
  Future<List<Task>> getTasks({TaskStatus? status, String? search});

  Future<TaskSummary> getSummary();

  Future<Task> createTask(TaskInput input);

  Future<Task> updateTask(String id, TaskInput input);

  /// Cambia solo el estado (la casilla de la lista), sin reenviar el resto.
  Future<Task> changeStatus(String id, TaskStatus status);

  Future<void> deleteTask(String id);
}
