# features/agenda — Aprendiz B

Lista de agenda, formulario de tarea, perfil y CRUD de tareas contra `/api/tasks`.

## Estructura (igual que auth)
- `domain/`       `Task`, `TaskInput`, `TaskSummary`, contrato `TaskRepository` y un caso de uso por archivo
- `data/`         `TaskModel` (JSON), `TaskRemoteDataSource` (usa el `ApiClient` compartido), `TaskRepositoryImpl`
- `presentation/` `TaskProvider` (ChangeNotifier), paginas y widgets

## Pantallas
- `AgendaListPage` — la que muestra `AuthGate` tras el login. Busqueda, filtros por estado con conteo,
  orden (fecha / prioridad / titulo), completar con la casilla, detalle, editar y eliminar con confirmacion.
- `TaskFormPage` — ruta `/task-form`. Sin argumento crea; con una `Task` como argumento la edita.
- `ProfilePage` — ruta `/profile`. Es de B pero vive en `features/auth/presentation/pages/`, donde la
  pone la estructura del taller. Datos del `AuthProvider` (A), resumen de tareas y cerrar sesion.

## Decisiones que conviene no deshacer
- El formulario usa `SingleChildScrollView` y no `ListView`: `ListView` desmonta los campos fuera de
  pantalla y `validate()` deja de revisarlos.
- La franja de color de la tarjeta es un **borde**, no un `Container` en un `Row` con `stretch`:
  dentro de un `ListView` eso colapsa la tarjeta a altura cero sin dar error.
- `TaskProvider` descarta respuestas viejas (numero de peticion): al escribir en el buscador, una
  respuesta que llega tarde no pisa a la nueva.
- `TaskProvider.reset()` al abrir la agenda: el provider vive toda la app y, sin esto, tras cerrar
  sesion y entrar con otra cuenta se verian un instante las tareas de la anterior.
- Fechas en español escritas a mano (`utils/date_labels.dart`) para no sumar `intl`.

## Pruebas
`flutter test test/agenda_test.dart` — provider, fechas y pantallas (19 casos, con `test/fakes/`).
