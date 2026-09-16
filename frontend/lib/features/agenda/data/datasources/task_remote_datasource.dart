import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_input.dart';
import '../../domain/entities/task_summary.dart';
import '../models/task_model.dart';

/// Habla con los endpoints /api/tasks/* del backend.
/// El token lo agrega solo el ApiClient compartido.
class TaskRemoteDataSource {
  const TaskRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<TaskModel>> getTasks({TaskStatus? status, String? search}) async {
    final query = <String, String>{
      if (status != null) 'status': status.apiValue,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    // Uri codifica la busqueda (espacios, tildes, "&"...). Pegarla a mano en el texto la romperia.
    final path = Uri(path: ApiConstants.tasks, queryParameters: query.isEmpty ? null : query).toString();

    final res = await _api.get(path);
    final list = res.data['tasks'] as List<dynamic>;
    return list.map((json) => TaskModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TaskSummary> getSummary() async {
    final res = await _api.get(ApiConstants.taskSummary);
    return TaskModel.summaryFromJson(res.data['summary'] as Map<String, dynamic>);
  }

  Future<TaskModel> createTask(TaskInput input) async {
    final res = await _api.post(ApiConstants.tasks, TaskModel.inputToJson(input));
    return _readTask(res);
  }

  Future<TaskModel> updateTask(String id, TaskInput input) async {
    final res = await _api.put('${ApiConstants.tasks}/$id', TaskModel.inputToJson(input));
    return _readTask(res);
  }

  /// PUT parcial con solo el estado: el backend deriva completedAt.
  Future<TaskModel> changeStatus(String id, TaskStatus status) async {
    final res = await _api.put('${ApiConstants.tasks}/$id', {'status': status.apiValue});
    return _readTask(res);
  }

  Future<void> deleteTask(String id) => _api.delete('${ApiConstants.tasks}/$id');

  TaskModel _readTask(ApiResponse res) => TaskModel.fromJson(res.data['task'] as Map<String, dynamic>);
}
