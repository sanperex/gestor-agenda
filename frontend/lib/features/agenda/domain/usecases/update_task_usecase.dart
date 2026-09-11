import '../entities/task.dart';
import '../entities/task_input.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: editar una tarea desde el formulario.
class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(String id, TaskInput input) => _repository.updateTask(id, input);
}
