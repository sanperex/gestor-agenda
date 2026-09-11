import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gestor_agenda/app/app.dart';
import 'package:gestor_agenda/features/agenda/domain/entities/task.dart';
import 'package:gestor_agenda/features/agenda/domain/entities/task_input.dart';
import 'package:gestor_agenda/features/agenda/presentation/providers/task_provider.dart';
import 'package:gestor_agenda/features/agenda/presentation/utils/date_labels.dart';
import 'package:gestor_agenda/features/auth/domain/entities/forgot_password_result.dart';
import 'package:gestor_agenda/features/auth/domain/entities/user.dart';
import 'package:gestor_agenda/features/auth/domain/repositories/auth_repository.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/login_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/logout_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/register_usecase.dart';
import 'package:gestor_agenda/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:gestor_agenda/features/auth/presentation/providers/auth_provider.dart';

import 'fakes/fake_task_repository.dart';

// Pruebas del modulo de agenda (Aprendiz B).

/// Auth falso con la sesion ya iniciada: la app abre directo en la agenda.
class _LoggedInAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentUser() async => const User(id: 'u1', name: 'Ana María Torres', email: 'ana@test.com');

  @override
  Future<void> logout() async {}

  @override
  Future<User> login({required String email, required String password}) => throw UnimplementedError();

  @override
  Future<User> register({required String name, required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) => throw UnimplementedError();

  @override
  Future<String> resetPassword({required String email, required String code, required String newPassword}) =>
      throw UnimplementedError();
}

List<Task> _sampleTasks() => [
  sampleTask(id: '1', title: 'Entregar informe', description: 'Consolidado mensual', priority: TaskPriority.high),
  sampleTask(id: '2', title: 'Reunión de equipo', dueDate: DateTime(2030, 1, 10, 9)),
  sampleTask(id: '3', title: 'Comprar materiales', status: TaskStatus.completed, priority: TaskPriority.low),
];

Future<FakeTaskRepository> _pumpAgenda(WidgetTester tester, {List<Task>? tasks}) async {
  final repo = FakeTaskRepository(tasks ?? _sampleTasks());
  final authRepo = _LoggedInAuthRepository();
  final auth = AuthProvider(
    login: LoginUseCase(authRepo),
    register: RegisterUseCase(authRepo),
    getCurrentUser: GetCurrentUserUseCase(authRepo),
    forgotPassword: ForgotPasswordUseCase(authRepo),
    resetPassword: ResetPasswordUseCase(authRepo),
    logout: LogoutUseCase(authRepo),
  );
  await auth.checkSession();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: buildTaskProvider(repo)),
      ],
      child: const GestorAgendaApp(),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('TaskProvider', () {
    test('carga las tareas por fecha y el resumen', () async {
      final provider = buildTaskProvider(FakeTaskRepository(_sampleTasks()));
      await provider.load();

      expect(provider.tasks.map((t) => t.title).first, 'Reunión de equipo');
      expect(provider.summary.total, 3);
      expect(provider.summary.completed, 1);
      expect(provider.listError, isNull);
    });

    test('filtra por estado y busca por texto', () async {
      final provider = buildTaskProvider(FakeTaskRepository(_sampleTasks()));

      await provider.setStatusFilter(TaskStatus.completed);
      expect(provider.tasks.single.title, 'Comprar materiales');

      await provider.setStatusFilter(null);
      await provider.setSearch('  CONSOLIDADO ');
      expect(provider.tasks.single.title, 'Entregar informe', reason: 'busca en la descripcion y sin mayusculas');
    });

    test('ordena por prioridad y por título sin ir al servidor', () async {
      final provider = buildTaskProvider(FakeTaskRepository(_sampleTasks()));
      await provider.load();

      provider.setSort(TaskSort.priority);
      expect(provider.tasks.first.priority, TaskPriority.high);
      expect(provider.tasks.last.priority, TaskPriority.low);

      provider.setSort(TaskSort.title);
      expect(provider.tasks.map((t) => t.title).toList(), [
        'Comprar materiales',
        'Entregar informe',
        'Reunión de equipo',
      ]);
    });

    test('marcar como completada actualiza la tarea y el resumen', () async {
      final provider = buildTaskProvider(FakeTaskRepository(_sampleTasks()));
      await provider.load();
      final task = provider.tasks.firstWhere((t) => t.id == '1');

      expect(await provider.toggleCompleted(task), isTrue);
      expect(provider.tasks.firstWhere((t) => t.id == '1').isCompleted, isTrue);
      expect(provider.summary.completed, 2);
    });

    test('si la API rechaza, devuelve false y deja el motivo', () async {
      final repo = FakeTaskRepository()..failNextWith = 'El título es obligatorio';
      final provider = buildTaskProvider(repo);

      final ok = await provider.create(
        TaskInput(
          title: '',
          description: '',
          dueDate: DateTime(2030),
          location: '',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
        ),
      );
      expect(ok, isFalse);
      expect(provider.errorMessage, 'El título es obligatorio');
      expect(provider.isSaving, isFalse);
    });

    test('una respuesta vieja de la búsqueda no pisa a la nueva', () async {
      final repo = _SlowSearchRepository(_sampleTasks());
      final provider = buildTaskProvider(repo);

      final first = provider.setSearch('entregar'); // queda esperando
      final second = provider.setSearch('reunión'); // tambien espera

      repo.release('reunión'); // la nueva responde primero
      await second;
      repo.release('entregar'); // la vieja llega tarde
      await first;

      expect(provider.tasks.single.title, 'Reunión de equipo');
    });

    test('reset olvida las tareas de la cuenta anterior', () async {
      final provider = buildTaskProvider(FakeTaskRepository(_sampleTasks()));
      await provider.setStatusFilter(TaskStatus.pending);

      provider.reset();
      expect(provider.tasks, isEmpty);
      expect(provider.summary.total, 0);
      expect(provider.statusFilter, isNull);
    });
  });

  group('Fechas en español', () {
    final now = DateTime(2026, 9, 11, 23, 0);

    test('hoy, mañana y ayer por día calendario', () {
      expect(dueLabel(DateTime(2026, 9, 11, 15, 5), now: now), 'Hoy, 3:05 p. m.');
      // Faltan 2 horas, pero es otro dia: "Mañana", no "Hoy".
      expect(dueLabel(DateTime(2026, 9, 12, 1, 0), now: now), 'Mañana, 1:00 a. m.');
      expect(dueLabel(DateTime(2026, 9, 10, 9, 30), now: now), 'Ayer, 9:30 a. m.');
    });

    test('otras fechas con mes corto, y año solo si no es el actual', () {
      expect(dueLabel(DateTime(2026, 12, 24, 20, 0), now: now), '24 dic, 8:00 p. m.');
      expect(dueLabel(DateTime(2027, 1, 3, 8, 0), now: now), '3 ene 2027, 8:00 a. m.');
    });

    test('medianoche y mediodía son las 12', () {
      expect(timeLabel(DateTime(2026, 1, 1, 0, 0)), '12:00 a. m.');
      expect(timeLabel(DateTime(2026, 1, 1, 12, 0)), '12:00 p. m.');
      expect(longDateLabel(DateTime(2026, 9, 11)), 'viernes 11 de septiembre de 2026');
    });
  });

  group('Pantallas de agenda', () {
    testWidgets('muestra el saludo, los filtros con conteo y las tareas', (tester) async {
      await _pumpAgenda(tester);

      expect(find.text('Hola, Ana María Torres'), findsOneWidget);
      expect(find.text('Tienes 2 tareas por hacer'), findsOneWidget);
      expect(find.text('Todas (3)'), findsOneWidget);
      expect(find.text('Completada (1)'), findsOneWidget);
      expect(find.text('Entregar informe'), findsOneWidget);
      expect(find.text('Reunión de equipo'), findsOneWidget);
    });

    testWidgets('sin tareas invita a crear la primera', (tester) async {
      await _pumpAgenda(tester, tasks: []);
      expect(find.text('Aún no tienes tareas'), findsOneWidget);
    });

    testWidgets('el filtro muestra solo ese estado y tocarlo otra vez lo quita', (tester) async {
      await _pumpAgenda(tester);

      await tester.tap(find.text('Completada (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Comprar materiales'), findsOneWidget);
      expect(find.text('Entregar informe'), findsNothing);

      await tester.tap(find.text('Completada (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Entregar informe'), findsOneWidget);
    });

    testWidgets('crear una tarea desde el formulario la agrega a la lista', (tester) async {
      await _pumpAgenda(tester, tasks: []);

      await tester.tap(find.text('Nueva tarea'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Crear tarea'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Título'), 'Sustentar el taller');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.pumpAndSettle();

      expect(find.text('Sustentar el taller'), findsOneWidget);
      expect(find.text('Tarea creada'), findsOneWidget);
    });

    testWidgets('el formulario no deja guardar sin título', (tester) async {
      await _pumpAgenda(tester, tasks: []);

      await tester.tap(find.text('Nueva tarea'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.pump();

      expect(find.text('Escribe un título'), findsOneWidget);
    });

    testWidgets('si la API rechaza, el formulario sigue abierto con lo escrito', (tester) async {
      final repo = await _pumpAgenda(tester, tasks: []);

      await tester.tap(find.text('Nueva tarea'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Título'), 'Algo');
      repo.failNextWith = 'La fecha no es válida';
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear tarea'));
      await tester.pumpAndSettle();

      expect(find.text('La fecha no es válida'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Crear tarea'), findsOneWidget, reason: 'no se cerro');
      expect(find.text('Algo'), findsOneWidget, reason: 'no se perdio lo escrito');
    });

    testWidgets('eliminar pide confirmación y quita la tarea', (tester) async {
      await _pumpAgenda(
        tester,
        tasks: [sampleTask(id: '1', title: 'Tarea a borrar')],
      );

      await tester.tap(find.byTooltip('Acciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Se eliminará "Tarea a borrar". Esta acción no se puede deshacer.'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('Tarea a borrar'), findsNothing);
      expect(find.text('Tarea eliminada'), findsOneWidget);
    });

    testWidgets('la casilla marca la tarea como completada', (tester) async {
      await _pumpAgenda(
        tester,
        tasks: [sampleTask(id: '1', title: 'Llamar al instructor')],
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
      expect(find.text('Todo al día'), findsOneWidget);
    });

    testWidgets('el perfil muestra nombre, correo, iniciales y el resumen', (tester) async {
      await _pumpAgenda(tester);

      await tester.tap(find.byTooltip('Mi perfil'));
      await tester.pumpAndSettle();

      expect(find.text('AM'), findsOneWidget);
      expect(find.text('ana@test.com'), findsWidgets);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cerrar sesión'), findsOneWidget);
    });
  });
}

/// Repositorio donde cada busqueda espera a que la prueba la libere, para poder
/// hacer que las respuestas lleguen en el orden que se quiera.
class _SlowSearchRepository extends FakeTaskRepository {
  _SlowSearchRepository(super.initial);

  final _pending = <String, Completer<void>>{};

  void release(String search) => _pending[search]!.complete();

  @override
  Future<List<Task>> getTasks({TaskStatus? status, String? search}) async {
    final gate = Completer<void>();
    _pending[search ?? ''] = gate;
    await gate.future;
    return super.getTasks(status: status, search: search);
  }
}
