# Contrato de la API (A <-> B)

## Para que sirve
Reglas que ambos modulos respetan para no romperse entre si.

## Formato de respuesta
```json
{ "success": true,  "message": "...", "data": { } }
{ "success": false, "message": "...", "errors": ["..."] }
```
Backend: `sendSuccess(res, status, data, message)` y `throw new ApiError(status, message)`.

## Endpoints de A (auth)
| Metodo | Ruta | Body | OK | Errores |
|---|---|---|---|---|
| POST | /api/auth/register | name, email, password | 201 {user, token} | 400, 409 |
| POST | /api/auth/login | email, password | 200 {user, token} | 400, 401 |
| GET | /api/auth/me | (token) | 200 {user} | 401, 404 |
| POST | /api/auth/forgot-password | email | 200 {demoCode?} | 400 |
| POST | /api/auth/reset-password | email, code, newPassword | 200 | 400, 429 |
| GET | /api/health | - | 200 {db} | - |

`user` = `{ id, name, email, createdAt, updatedAt }`.

## Endpoints de B (tareas)
Todos privados (`requireAuth`). Coleccion `tareas`, modelo `Task`.

| Metodo | Ruta | Body / query | OK | Errores |
|---|---|---|---|---|
| GET | /api/tasks | ?status=pending\|inProgress\|completed &search=texto | 200 {tasks} | 400, 401 |
| GET | /api/tasks/summary | - | 200 {summary} | 401 |
| GET | /api/tasks/:id | - | 200 {task} | 401, 404 |
| POST | /api/tasks | title, dueDate, description?, location?, status?, priority? | 201 {task} | 400, 401 |
| PUT | /api/tasks/:id | cualquier campo del POST (edicion parcial) | 200 {task} | 400, 401, 404 |
| DELETE | /api/tasks/:id | - | 200 {} | 401, 404 |

`task` = `{ id, userId, title, description, dueDate, location, status, priority, completedAt, createdAt, updatedAt }`.
`summary` = `{ total, pending, inProgress, completed }`.

- `status`: `pending` | `inProgress` | `completed`. `priority`: `low` | `medium` | `high`.
- `dueDate` en ISO 8601 (el Flutter la manda en UTC).
- `completedAt` lo pone el backend al pasar a `completed` y lo borra al salir; el cliente no lo manda.
- `data` siempre es un objeto (`{tasks: [...]}`), nunca una lista suelta: el `ApiClient` de Flutter lee `data` como Map.
- No hay PATCH: marcar como completada es `PUT /api/tasks/:id` con `{ "status": "completed" }`.
- Toda consulta filtra por `{ _id, userId }`: una tarea ajena responde 404, igual que una que no existe.
- Un id mal formado responde 404 (no llega a Mongo; si llegara, el CastError seria un 500).
- Pruebas: `cd backend && npm run test:tasks` (12 casos contra un MongoDB real; usa una base `*_test` y la borra).

## Como usa B la autenticacion
Backend:
```js
const requireAuth = require('../middlewares/auth.middleware');
router.use(requireAuth);
// en el controlador:
Task.find({ userId: req.userId });
Task.create({ ...datos, userId: req.userId }); // userId NUNCA viene del cliente
```
Modelo: `userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true }`.
Colecciones en Atlas (base `gestor_agenda`): `usuarios` (A). Sugerido para B: `tareas`
-> `model('Task', taskSchema, 'tareas')`.

Flutter:
- `context.read<ApiClient>()` -> `get/post/put/delete`. El token se agrega solo.
- Errores: `AppException.message` listo para mostrar.
- Perfil: `context.watch<AuthProvider>().user` y `context.read<AuthProvider>().logout()`.
- Pantalla despues del login: cambiar `AgendaPlaceholderPage` en `lib/app/auth_gate.dart`.
- Rutas nuevas: `lib/app/routes.dart`. Providers nuevos: `lib/main.dart`.
- Registrar rutas backend: `backend/src/app.js` (linea comentada `/api/tasks`).
