import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: marcar una tarea como completada (o volverla a pendiente).
class ChangeTaskStatusUseCase {
  const ChangeTaskStatusUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(String id, TaskStatus status) => _repository.changeStatus(id, status);
}
