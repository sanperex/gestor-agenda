import '../entities/task.dart';
import '../entities/task_input.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: crear una tarea.
class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);

  final TaskRepository _repository;

  Future<Task> call(TaskInput input) => _repository.createTask(input);
}
