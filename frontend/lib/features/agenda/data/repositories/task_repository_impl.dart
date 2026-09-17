import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../../domain/entities/task_summary.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

/// Implementacion real del contrato. Las tareas viven solo en la API (MongoDB),
/// no en el telefono: por eso no hay datasource local, a diferencia de auth.
class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._remote);

  final TaskRemoteDataSource _remote;

  @override
  Future<List<Task>> getTasks({TaskStatus? status, String? search}) {
    return _remote.getTasks(status: status, search: search);
  }

  @override
  Future<TaskSummary> getSummary() => _remote.getSummary();

  @override
  Future<Task> createTask(TaskInput input) => _remote.createTask(input);

  @override
  Future<Task> updateTask(String id, TaskInput input) => _remote.updateTask(id, input);

  @override
  Future<Task> changeStatus(String id, TaskStatus status) => _remote.changeStatus(id, status);

  @override
  Future<void> deleteTask(String id) => _remote.deleteTask(id);
}
