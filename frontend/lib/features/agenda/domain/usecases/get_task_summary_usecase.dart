import '../entities/task_summary.dart';
import '../repositories/task_repository.dart';

/// Caso de uso: contar las tareas por estado.
class GetTaskSummaryUseCase {
  const GetTaskSummaryUseCase(this._repository);

  final TaskRepository _repository;

  Future<TaskSummary> call() => _repository.getSummary();
}
