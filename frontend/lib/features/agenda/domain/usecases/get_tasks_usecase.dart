import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: listar las tareas del usuario.
class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call({TaskStatus? status, String? search}) {
    return _repository.getTasks(status: status, search: search);
  }
}
