import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../../domain/entities/task_summary.dart';
import '../../domain/usecases/change_task_status_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/get_task_summary_usecase.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

/// Orden de la lista. No va al servidor: la lista ya llega por fecha y
/// reordenarla en memoria evita un viaje de red por cada toque.
enum TaskSort {
  date('Por fecha'),
  priority('Por prioridad'),
  title('Por título');

  const TaskSort(this.label);

  final String label;
}

/// Estado de la agenda (Aprendiz B).
///
/// Las pantallas escuchan: [tasks], [summary], [isLoading], [listError] y los filtros.
/// Las acciones (crear, editar, borrar...) devuelven true/false; si fallan, el motivo
/// queda en [errorMessage], igual que en AuthProvider.
class TaskProvider extends ChangeNotifier {
  TaskProvider({
    required this._getTasks,
    required this._getSummary,
    required this._createTask,
    required this._updateTask,
    required this._changeStatus,
    required this._deleteTask,
  });

  final GetTasksUseCase _getTasks;
  final GetTaskSummaryUseCase _getSummary;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final ChangeTaskStatusUseCase _changeStatus;
  final DeleteTaskUseCase _deleteTask;

  List<Task> _tasks = [];
  TaskSummary _summary = const TaskSummary();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _listError;
  String? _errorMessage;
  TaskStatus? _statusFilter;
  String _search = '';
  TaskSort _sort = TaskSort.date;

  // Cada carga lleva un numero. Si llega la respuesta de una carga vieja (el usuario
  // siguio escribiendo en el buscador), se descarta: si no, la lista mostraria
  // el resultado de una busqueda anterior.
  int _lastRequest = 0;

  TaskSummary get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get listError => _listError;
  String? get errorMessage => _errorMessage;
  TaskStatus? get statusFilter => _statusFilter;
  String get search => _search;
  TaskSort get sort => _sort;
  bool get hasFilters => _statusFilter != null || _search.isNotEmpty;

  /// Las tareas ya ordenadas segun [sort].
  List<Task> get tasks {
    final sorted = List<Task>.of(_tasks);
    switch (_sort) {
      case TaskSort.date:
        sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case TaskSort.priority:
        // De Alta a Baja; dentro de la misma prioridad, la mas proxima primero.
        sorted.sort((a, b) {
          final byPriority = b.priority.index.compareTo(a.priority.index);
          return byPriority != 0 ? byPriority : a.dueDate.compareTo(b.dueDate);
        });
      case TaskSort.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return sorted;
  }

  /// Borra todo lo del usuario anterior. Lo llama la agenda al abrirse, porque tras
  /// cerrar sesion y entrar con otra cuenta este provider es el mismo objeto.
  /// No avisa a nadie: se llama antes del primer dibujo.
  void reset() {
    _tasks = [];
    _summary = const TaskSummary();
    _listError = null;
    _errorMessage = null;
    _statusFilter = null;
    _search = '';
    _sort = TaskSort.date;
    _lastRequest++;
  }

  /// Trae la lista (con el filtro y la busqueda actuales) y el resumen a la vez.
  Future<void> load() async {
    final request = ++_lastRequest;
    _isLoading = true;
    _listError = null;
    notifyListeners();

    try {
      final results = await Future.wait([_getTasks(status: _statusFilter, search: _search), _getSummary()]);
      if (request != _lastRequest) return;
      _tasks = results[0] as List<Task>;
      _summary = results[1] as TaskSummary;
    } on AppException catch (e) {
      if (request != _lastRequest) return;
      _listError = e.message;
    } catch (e) {
      if (request != _lastRequest) return;
      debugPrint('Error inesperado: $e');
      _listError = 'Ocurrió un error inesperado';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tocar el filtro activo lo quita (null = todas).
  Future<void> setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    return load();
  }

  Future<void> setSearch(String value) {
    _search = value.trim();
    return load();
  }

  void setSort(TaskSort value) {
    _sort = value;
    notifyListeners();
  }

  Future<bool> create(TaskInput input) => _save(() => _createTask(input));

  Future<bool> update(String id, TaskInput input) => _save(() => _updateTask(id, input));

  /// La casilla de la lista: completada <-> pendiente.
  Future<bool> toggleCompleted(Task task) {
    final next = task.isCompleted ? TaskStatus.pending : TaskStatus.completed;
    return _save(() => _changeStatus(task.id, next));
  }

  Future<bool> delete(String id) => _save(() => _deleteTask(id));

  /// Ejecuta una accion y, si sale bien, recarga desde el servidor.
  ///
  /// Se recarga en vez de tocar la lista a mano: el servidor decide el id, el orden y
  /// completedAt, y una lista armada en el telefono se desincroniza al primer fallo.
  Future<bool> _save(Future<Object?> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      _errorMessage = 'Ocurrió un error inesperado';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
