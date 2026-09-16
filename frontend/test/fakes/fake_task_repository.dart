import 'package:gestor_agenda/core/errors/app_exception.dart';
import 'package:gestor_agenda/features/agenda/domain/entities/task.dart';
import 'package:gestor_agenda/features/agenda/domain/entities/task_input.dart';
import 'package:gestor_agenda/features/agenda/domain/entities/task_summary.dart';
import 'package:gestor_agenda/features/agenda/domain/repositories/task_repository.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/change_task_status_usecase.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/create_task_usecase.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/delete_task_usecase.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/get_task_summary_usecase.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/get_tasks_usecase.dart';
import 'package:gestor_agenda/features/agenda/domain/usecases/update_task_usecase.dart';
import 'package:gestor_agenda/features/agenda/presentation/providers/task_provider.dart';

/// Repositorio de tareas en memoria: permite probar las pantallas sin backend.
/// Se comporta como la API: filtra por estado y texto, y la lista sale por fecha.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task>? initial]) : _tasks = [...?initial];

  final List<Task> _tasks;
  int _nextId = 100;

  /// Si se pone, la siguiente operacion falla con este mensaje (como un 400 de la API).
  String? failNextWith;

  void _maybeFail() {
    final message = failNextWith;
    if (message != null) {
      failNextWith = null;
      throw AppException(message, statusCode: 400);
    }
  }

  @override
  Future<List<Task>> getTasks({TaskStatus? status, String? search}) async {
    _maybeFail();
    final text = search?.toLowerCase() ?? '';
    final result = _tasks.where((t) {
      final matchesStatus = status == null || t.status == status;
      final matchesText =
          text.isEmpty || t.title.toLowerCase().contains(text) || t.description.toLowerCase().contains(text);
      return matchesStatus && matchesText;
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  @override
  Future<TaskSummary> getSummary() async {
    int count(TaskStatus s) => _tasks.where((t) => t.status == s).length;
    return TaskSummary(
      total: _tasks.length,
      pending: count(TaskStatus.pending),
      inProgress: count(TaskStatus.inProgress),
      completed: count(TaskStatus.completed),
    );
  }

  @override
  Future<Task> createTask(TaskInput input) async {
    _maybeFail();
    final task = _fromInput('${_nextId++}', input);
    _tasks.add(task);
    return task;
  }

  @override
  Future<Task> updateTask(String id, TaskInput input) async {
    _maybeFail();
    final i = _tasks.indexWhere((t) => t.id == id);
    _tasks[i] = _fromInput(id, input);
    return _tasks[i];
  }

  @override
  Future<Task> changeStatus(String id, TaskStatus status) async {
    _maybeFail();
    final i = _tasks.indexWhere((t) => t.id == id);
    final t = _tasks[i];
    _tasks[i] = Task(
      id: t.id,
      title: t.title,
      description: t.description,
      dueDate: t.dueDate,
      location: t.location,
      status: status,
      priority: t.priority,
      completedAt: status == TaskStatus.completed ? DateTime.now() : null,
    );
    return _tasks[i];
  }

  @override
  Future<void> deleteTask(String id) async {
    _maybeFail();
    _tasks.removeWhere((t) => t.id == id);
  }

  Task _fromInput(String id, TaskInput input) => Task(
    id: id,
    title: input.title,
    description: input.description,
    dueDate: input.dueDate,
    location: input.location,
    status: input.status,
    priority: input.priority,
  );
}

/// Arma un TaskProvider real sobre el repositorio falso.
TaskProvider buildTaskProvider(TaskRepository repo) => TaskProvider(
  getTasks: GetTasksUseCase(repo),
  getSummary: GetTaskSummaryUseCase(repo),
  createTask: CreateTaskUseCase(repo),
  updateTask: UpdateTaskUseCase(repo),
  changeStatus: ChangeTaskStatusUseCase(repo),
  deleteTask: DeleteTaskUseCase(repo),
);

/// Tarea de ejemplo con valores por defecto.
Task sampleTask({
  required String id,
  required String title,
  String description = '',
  DateTime? dueDate,
  TaskStatus status = TaskStatus.pending,
  TaskPriority priority = TaskPriority.medium,
}) => Task(
  id: id,
  title: title,
  description: description,
  dueDate: dueDate ?? DateTime(2030, 1, 15, 10),
  location: '',
  status: status,
  priority: priority,
);
