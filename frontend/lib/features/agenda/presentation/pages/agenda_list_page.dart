import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_summary.dart';
import '../providers/task_provider.dart';
import '../utils/date_labels.dart';
import '../widgets/status_badge.dart';
import '../widgets/task_card.dart';

/// Pantalla principal despues del login (Aprendiz B): lista, busca, filtra y ordena
/// las tareas, y lleva a crear, editar, completar y eliminar.
class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  final _searchController = TextEditingController();

  // Espera a que el usuario deje de escribir antes de buscar, para no mandar
  // una peticion por cada letra.
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Esta pantalla se crea de nuevo en cada login (la monta AuthGate), asi que es el
    // momento de olvidar las tareas de la cuenta anterior y traer las de esta.
    final tasks = context.read<TaskProvider>()..reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tasks.load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) context.read<TaskProvider>().setSearch(value);
    });
  }

  void _openForm([Task? task]) {
    Navigator.of(context).pushNamed(AppRoutes.taskForm, arguments: task);
  }

  Future<void> _toggle(Task task) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TaskProvider>();
    final ok = await provider.toggleCompleted(task);
    if (!ok) {
      showMessage(messenger, provider.errorMessage ?? 'No se pudo actualizar', isError: true);
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        // Se nombra la tarea: con la lista tapada por el dialogo no hay forma de ver cual era.
        content: Text('Se eliminará "${task.title}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.delete(task.id);
    showMessage(messenger, ok ? 'Tarea eliminada' : provider.errorMessage ?? 'No se pudo eliminar', isError: !ok);
  }

  void _showDetail(Task task) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TaskDetail(
        task: task,
        onEdit: () {
          Navigator.pop(context);
          _openForm(task);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((p) => p.user);
    final tasks = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi agenda'),
        actions: [
          PopupMenuButton<TaskSort>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort),
            initialValue: tasks.sort,
            onSelected: tasks.setSort,
            itemBuilder: (_) => [for (final s in TaskSort.values) PopupMenuItem(value: s, child: Text(s.label))],
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _Header(name: user?.name ?? '', summary: tasks.summary),
          _SearchField(controller: _searchController, onChanged: _onSearchChanged),
          _StatusFilters(provider: tasks),
          Expanded(child: _buildBody(tasks)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }

  Widget _buildBody(TaskProvider tasks) {
    // El circulo de carga solo si todavia no hay nada que mostrar: reemplazar una lista
    // que ya se ve por un spinner en cada recarga haria parpadear toda la pantalla.
    if (tasks.isLoading && tasks.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tasks.listError != null) {
      return _ErrorView(message: tasks.listError!, onRetry: tasks.load);
    }
    final list = tasks.tasks;
    if (list.isEmpty) {
      return _EmptyView(hasFilters: tasks.hasFilters);
    }

    return RefreshIndicator(
      onRefresh: tasks.load,
      child: ListView.builder(
        // Espacio abajo para que el boton flotante no tape la ultima tarea.
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final task = list[i];
          return TaskCard(
            task: task,
            onTap: () => _showDetail(task),
            onToggle: () => _toggle(task),
            onEdit: () => _openForm(task),
            onDelete: () => _confirmDelete(task),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.summary});

  final String name;
  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final open = summary.pending + summary.inProgress;
    final subtitle = switch (open) {
      0 when summary.total == 0 => 'Crea tu primera tarea con el botón de abajo',
      0 => 'Todo al día',
      1 => 'Tienes 1 tarea por hacer',
      _ => 'Tienes $open tareas por hacer',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar por título o descripción',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          // La X aparece solo si hay texto.
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.provider});

  final TaskProvider provider;

  int _count(TaskStatus? status) => switch (status) {
    null => provider.summary.total,
    TaskStatus.pending => provider.summary.pending,
    TaskStatus.inProgress => provider.summary.inProgress,
    TaskStatus.completed => provider.summary.completed,
  };

  @override
  Widget build(BuildContext context) {
    final options = <TaskStatus?>[null, ...TaskStatus.values];

    return SizedBox(
      height: 48,
      // Desliza en horizontal: cuatro filtros no caben a lo ancho en un celular.
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final status = options[i];
          final selected = provider.statusFilter == status;
          final label = status?.label ?? 'Todas';
          return FilterChip(
            label: Text('$label (${_count(status)})'),
            selected: selected,
            selectedColor: status == null ? null : TaskColors.status(status).withValues(alpha: 0.18),
            // Tocar el filtro activo lo quita: es lo primero que la gente intenta.
            onSelected: (_) => provider.setStatusFilter(selected ? null : status),
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    // "No tienes tareas" y "nada coincide con el filtro" piden cosas distintas al usuario.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hasFilters ? Icons.search_off : Icons.event_available_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'Ninguna tarea coincide' : 'Aún no tienes tareas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hasFilters ? 'Prueba con otro texto o quita el filtro.' : 'Toca "Nueva tarea" para crear la primera.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.error),
            const SizedBox(height: 12),
            Text('No se pudieron cargar las tareas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            // El mensaje real de la API: suele decir exactamente que falta (servidor apagado, sesion vencida).
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDetail extends StatelessWidget {
  const _TaskDetail({required this.task, required this.onEdit});

  final Task task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 12),
                PriorityLabel(priority: task.priority),
              ],
            ),
            const Divider(height: 28),
            if (task.description.isNotEmpty) _row(Icons.notes, 'Descripción', task.description),
            _row(Icons.event, 'Fecha', '${longDateLabel(task.dueDate)}, ${timeLabel(task.dueDate)}'),
            if (task.location.isNotEmpty) _row(Icons.place_outlined, 'Ubicación', task.location),
            if (task.completedAt != null)
              _row(
                Icons.check_circle_outline,
                'Completada',
                '${longDateLabel(task.completedAt!)}, ${timeLabel(task.completedAt!)}',
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
