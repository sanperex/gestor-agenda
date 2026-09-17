/// Cuantas tareas tiene el usuario en cada estado (GET /api/tasks/summary).
class TaskSummary {
  const TaskSummary({this.total = 0, this.pending = 0, this.inProgress = 0, this.completed = 0});

  final int total;
  final int pending;
  final int inProgress;
  final int completed;
}
