import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/vivid.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/vivid_backdrop.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_summary.dart';
import '../providers/task_provider.dart';
import '../utils/date_labels.dart';
import '../widgets/agenda_bottom_bar.dart';
import '../widgets/progress_ring.dart';
import '../widgets/status_badge.dart';
import '../widgets/task_card.dart';
import '../widgets/task_sheet.dart';

/// Pantalla principal despues del login (Aprendiz B): lista, busca, filtra y ordena
/// las tareas, y lleva a crear, editar, completar y eliminar.
///
/// Cabecera índigo con saludo, progreso, buscador y filtros; la tarea en curso destacada
/// encima; y la lista agrupada por día sobre una hoja lavanda.
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
            style: TextButton.styleFrom(foregroundColor: Vivid.red),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Vivid.deep.withValues(alpha: 0.45),
      builder: (sheetContext) => TaskSheet(
        task: task,
        onToggle: () {
          Navigator.pop(sheetContext);
          _toggle(task);
        },
        onEdit: () {
          Navigator.pop(sheetContext);
          _openForm(task);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _confirmDelete(task);
        },
      ),
    );
  }

  /// Deslizar: a la derecha completa (o vuelve a pendiente), a la izquierda elimina.
  /// Siempre devuelve false: la tarjeta vuelve a su sitio y es la recarga desde el
  /// servidor la que la saca o la cambia. Si la tarjeta desapareciera antes de que el
  /// servidor conteste, Flutter se quejaria de un Dismissible que sigue en el arbol.
  Future<bool> _onSwipe(Task task, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      await _toggle(task);
    } else {
      await _confirmDelete(task);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthProvider, User?>((p) => p.user);
    final tasks = context.watch<TaskProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final all = tasks.tasks;
    // La tarea en curso sube a la tarjeta destacada y sale de la lista, para no verla dos veces.
    final featured = all.where((t) => t.status == TaskStatus.inProgress && !t.isOverdue).firstOrNull;
    final rest = featured == null ? all : all.where((t) => t.id != featured.id).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Vivid.lavender,
        body: Stack(
          children: [
            RefreshIndicator(
              color: Vivid.accent,
              onRefresh: tasks.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      name: user?.name ?? '',
                      provider: tasks,
                      featured: featured,
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      onLogout: () => context.read<AuthProvider>().logout(),
                      onOpen: _showDetail,
                      onToggle: _toggle,
                    ),
                  ),
                  ..._body(tasks, rest, hasFeatured: featured != null),
                  SliverToBoxAdapter(child: SizedBox(height: 124 + bottomInset)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 120 + bottomInset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Vivid.lavender.withValues(alpha: 0), Vivid.lavender],
                      stops: const [0, 0.55],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 14 + bottomInset,
              child: AgendaBottomBar(
                current: AgendaTab.agenda,
                onAgenda: () {},
                onAdd: () => _openForm(),
                onProfile: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(TaskProvider tasks, List<Task> rest, {required bool hasFeatured}) {
    // El circulo de carga solo si todavia no hay nada que mostrar: reemplazar una lista
    // que ya se ve por un spinner en cada recarga haria parpadear toda la pantalla.
    if (tasks.isLoading && tasks.tasks.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: Vivid.accent)),
          ),
        ),
      ];
    }
    if (tasks.listError != null) {
      return [
        SliverToBoxAdapter(
          child: _ErrorView(message: tasks.listError!, onRetry: tasks.load),
        ),
      ];
    }
    if (tasks.tasks.isEmpty) {
      return [SliverToBoxAdapter(child: _EmptyView(hasFilters: tasks.hasFilters))];
    }

    final groups = _group(rest, tasks.sort);
    var index = 0;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(20, hasFeatured ? 16 : 4, 20, 0),
        sliver: SliverList.list(
          children: [
            for (final group in groups) ...[
              Entrance(
                key: ValueKey('grupo-${group.label}'),
                delay: Duration(milliseconds: 80 + 50 * index++),
                child: _GroupHeader(group: group),
              ),
              for (final task in group.tasks)
                Padding(
                  key: ValueKey('fila-${task.id}'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Entrance(
                    delay: Duration(milliseconds: 80 + 50 * index++),
                    child: Dismissible(
                      key: ValueKey('deslizar-${task.id}'),
                      background: SwipeBackground.complete(isCompleted: task.isCompleted),
                      secondaryBackground: const SwipeBackground.delete(),
                      confirmDismiss: (direction) => _onSwipe(task, direction),
                      child: TaskCard(task: task, onTap: () => _showDetail(task), onToggle: () => _toggle(task)),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ];
  }

  /// Agrupa por día (Vencidas, Hoy, Mañana, Más adelante, Anteriores) cuando se ordena
  /// por fecha. Con otro orden los grupos por día romperían ese orden, así que la lista
  /// va en un solo bloque.
  static List<_Group> _group(List<Task> list, TaskSort sort) {
    if (sort != TaskSort.date) return [if (list.isNotEmpty) _Group(sort.label, Vivid.accent, list)];

    final overdue = <Task>[], today = <Task>[], tomorrow = <Task>[], later = <Task>[], earlier = <Task>[];
    for (final t in list) {
      if (t.isOverdue) {
        overdue.add(t);
        continue;
      }
      final days = daysFromToday(t.dueDate);
      if (days == 0) {
        today.add(t);
      } else if (days == 1) {
        tomorrow.add(t);
      } else if (days > 1) {
        later.add(t);
      } else {
        earlier.add(t);
      }
    }

    // Dentro de cada día, lo hecho baja al final: lo que queda por hacer es lo que se busca.
    List<Task> pendingFirst(List<Task> xs) => [...xs.where((t) => !t.isCompleted), ...xs.where((t) => t.isCompleted)];

    return [
      if (overdue.isNotEmpty) _Group('Vencidas', Vivid.red, pendingFirst(overdue)),
      if (today.isNotEmpty) _Group('Hoy', Vivid.accent, pendingFirst(today)),
      if (tomorrow.isNotEmpty) _Group('Mañana', Vivid.cyan, pendingFirst(tomorrow)),
      if (later.isNotEmpty) _Group('Más adelante', Vivid.amber, pendingFirst(later)),
      if (earlier.isNotEmpty) _Group('Anteriores', Vivid.muted, pendingFirst(earlier)),
    ];
  }
}

class _Group {
  const _Group(this.label, this.color, this.tasks);

  final String label;
  final Color color;
  final List<Task> tasks;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _Group group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: group.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            group.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Vivid.ink),
          ),
          const Spacer(),
          Text(
            '${group.tasks.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Vivid.muted),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.provider,
    required this.featured,
    required this.searchController,
    required this.onSearchChanged,
    required this.onLogout,
    required this.onOpen,
    required this.onToggle,
  });

  final String name;
  final TaskProvider provider;
  final Task? featured;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLogout;
  final ValueChanged<Task> onOpen;
  final ValueChanged<Task> onToggle;

  static String _subtitle(TaskSummary s) {
    final open = s.pending + s.inProgress;
    if (open == 0) return s.total == 0 ? 'Crea tu primera tarea con el botón +' : 'Todo al día';
    return open == 1 ? 'Tienes 1 tarea por hacer' : 'Tienes $open tareas por hacer';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final summary = provider.summary;
    final task = featured;

    // El índigo termina a media altura de la tarjeta destacada y la hoja lavanda
    // empieza ahí, con las esquinas redondeadas: la tarjeta queda montada entre las dos.
    final colorBottom = task != null ? 80.0 : 0.0;
    final sheetHeight = task != null ? 110.0 : 30.0;

    return Stack(
      children: [
        Positioned.fill(bottom: colorBottom, child: const VividBackdrop()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: sheetHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Vivid.lavender,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, task != null ? 0 : 46),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Expanded + Align: la pastilla ocupa solo lo que necesita, pero en un celular
                  // angosto una fecha larga ("Miércoles 30 de septiembre") se recorta con puntos
                  // suspensivos en vez de desbordar la fila.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: Vivid.glass(radius: 999),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                headerDateLabel(DateTime.now()),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      fixedSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Entrance(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $name',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _subtitle(summary),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ProgressRing(done: summary.completed, total: summary.total),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Entrance(
                delay: const Duration(milliseconds: 50),
                child: _SearchField(controller: searchController, provider: provider, onChanged: onSearchChanged),
              ),
              const SizedBox(height: 12),
              Entrance(
                delay: const Duration(milliseconds: 100),
                child: _StatusFilters(provider: provider),
              ),
              if (task != null) ...[
                const SizedBox(height: 20),
                Entrance(
                  delay: const Duration(milliseconds: 150),
                  child: _FeaturedTask(task: task, onOpen: () => onOpen(task), onToggle: () => onToggle(task)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.provider, required this.onChanged});

  final TextEditingController controller;
  final TaskProvider provider;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: Vivid.glass(radius: 16),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: Colors.white, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Buscar por título o descripción',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          PopupMenuButton<TaskSort>(
            tooltip: 'Ordenar',
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            initialValue: provider.sort,
            onSelected: provider.setSort,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [for (final s in TaskSort.values) PopupMenuItem(value: s, child: Text(s.label))],
          ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = provider.summary;
    final options = <(TaskStatus?, String, int)>[
      (null, 'Todas', s.total),
      (TaskStatus.pending, 'Pendientes', s.pending),
      (TaskStatus.inProgress, 'En curso', s.inProgress),
      (TaskStatus.completed, 'Hechas', s.completed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (status, label, count) in options) ...[
            _FilterPill(
              label: label,
              count: count,
              selected: provider.statusFilter == status,
              // Tocar el filtro activo lo quita: es lo primero que la gente intenta.
              onTap: () => provider.setStatusFilter(provider.statusFilter == status ? null : status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.count, required this.selected, required this.onTap});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label, $count',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        decoration: selected
            ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999))
            : Vivid.glass(radius: 999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Vivid.accent : Colors.white,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 26),
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Vivid.soft(Vivid.accent) : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Vivid.accent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTask extends StatelessWidget {
  const _FeaturedTask({required this.task, required this.onOpen, required this.onToggle});

  final Task task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final when = daysFromToday(task.dueDate) == 0 ? timeLabel(task.dueDate) : dueLabel(task.dueDate);

    return Pressable(
      onTap: onOpen,
      semanticLabel: 'En curso: ${task.title}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Vivid.accentDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Vivid.shadow(strength: 1.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PulseDot(size: 8),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'EN CURSO · ${when.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                PriorityPill(priority: task.priority, onColor: true),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (task.location.isNotEmpty) ...[
                  Icon(Icons.place_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                IconButton(
                  tooltip: 'Marcar como completada',
                  onPressed: onToggle,
                  icon: const Icon(Icons.check_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Vivid.accentDark,
                    fixedSize: const Size(46, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Entrance(
      delay: const Duration(milliseconds: 120),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 36, 32, 0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Vivid.soft(Vivid.accent), borderRadius: BorderRadius.circular(26)),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.event_available_rounded,
                size: 38,
                color: Vivid.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Ninguna tarea coincide' : 'Aún no tienes tareas',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Vivid.ink),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters ? 'Prueba con otro texto o quita el filtro.' : 'Toca el botón + para crear la primera.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Vivid.muted, fontSize: 14),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: Vivid.soft(Vivid.red), borderRadius: BorderRadius.circular(26)),
            child: const Icon(Icons.cloud_off_rounded, size: 38, color: Vivid.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'No se pudieron cargar las tareas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Vivid.ink),
          ),
          const SizedBox(height: 6),
          // El mensaje real de la API: suele decir exactamente que falta (servidor apagado, sesion vencida).
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Vivid.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(backgroundColor: Vivid.accent, minimumSize: const Size(170, 50)),
          ),
        ],
      ),
    );
  }
}
