# 001 — Stack y arquitectura (2026-09-10)

## Para que sirve
Registro de las decisiones base. Si el instructor pregunta "por que", la respuesta esta aqui.

## Decisiones
| Tema | Elegido | Motivo corto |
|---|---|---|
| Repositorio | Monorepo: `backend/` + `frontend/` | un solo lugar, un solo GitFlow |
| Base de datos | MongoDB Atlas M0 (gratis) | requisito del grupo; Railway no tiene IP fija -> permitir 0.0.0.0/0 |
| ODM | Mongoose | esquemas, `unique`, `ref` a users |
| Nota consigna | La consigna dice "relacional"; el grupo decidio MongoDB | decision del equipo |
| Auth | JWT simple, 7 dias, sin refresh | suficiente para el taller |
| Login | solo correo + contrasena | un dato menos que validar |
| Hash | bcryptjs | JS puro, sin compilar en Windows/Railway |
| Recuperacion | codigo 6 digitos, hash + vence 15 min, modo demo (se ve en logs) | Railway no permite SMTP en planes gratis; correo real se puede enchufar despues |
| Backend deps | express, mongoose, bcryptjs, jsonwebtoken, cors | sin dotenv (`node --env-file`), sin nodemon (`node --watch`) |
| Backend estructura | config, models, controllers, routes, middlewares, utils | sin repositories/ ni services/ (capas vacias) |
| Flutter plataformas | Android + Web | pedido del proyecto |
| Flutter deps | http, provider, flutter_secure_storage | simples; sin dio, bloc, get_it, dartz, go_router |
| Arquitectura Flutter | Clean Architecture ligera | features/auth (A), features/agenda (B) |

## Contrato con B (resumen)
- Header `Authorization: Bearer <token>`; middleware `requireAuth` deja `req.userId`.
- `tasks.userId` = ObjectId ref 'User'. El cliente nunca manda userId.
- Respuesta: `{ success, data, message }`.
- Perfil (B) usa `GET /api/auth/me` y `logout()` del AuthProvider.
