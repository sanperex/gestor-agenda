import '../repositories/task_repository.dart';

/// Caso de uso: eliminar una tarea.
class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
