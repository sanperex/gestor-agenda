# Gestor de Agenda

Aplicación de agenda personal: cada usuario crea su cuenta, inicia sesión y administra sus propias
tareas. Hecha en Flutter (Android y Web) con una API REST en Node.js y base de datos MongoDB.

Taller 3 — SENA, Trimestre 5.

## Objetivo

Construir una aplicación completa de punta a punta: pantallas en Flutter, API REST propia, base de
datos en la nube, autenticación con JWT y despliegue público, trabajando en pareja con Git y GitFlow.

## Links

| Qué | URL |
|---|---|
| API (backend) | https://gestor-agenda-api.onrender.com |
| Estado de la API | https://gestor-agenda-api.onrender.com/api/health |
| App web | _(completar al desplegar el Static Site)_ |
| Repositorio | https://github.com/sanperex/gestor-agenda |

> La API está en el plan gratuito de Render: si nadie la usa por 15 minutos se duerme, y la primera
> petición puede tardar hasta un minuto. Después responde normal.

## Integrantes y roles

| Aprendiz | Nombre | Responsabilidad |
|---|---|---|
| A | **Santiago Pérez** ([@sanperex](https://github.com/sanperex)) | Autenticación: login, registro y recuperación de contraseña. Colección `usuarios`, endpoints `/api/auth/*`, JWT, integración Flutter–API y despliegue. |
| B | **Andrés Felipe Flórez** | Agenda: lista de tareas, formulario de tarea y perfil. Colección `tareas`, CRUD `/api/tasks` e integración de esas pantallas con la API. |

## Tecnologías

| Capa | Herramienta | Por qué |
|---|---|---|
| App | Flutter 3.47 / Dart (Android + Web) | Un solo código para celular y navegador |
| Estado | provider | Sencillo y suficiente para el tamaño del proyecto |
| HTTP | http | Peticiones REST sin dependencias extra |
| Token | flutter_secure_storage | Guarda el JWT cifrado en el dispositivo |
| API | Node.js 22+ / Express 5 | Estándar y muy documentado |
| Base de datos | MongoDB Atlas / Mongoose 9 | Esquemas, índices únicos y relaciones sencillas |
| Seguridad | bcryptjs + jsonwebtoken | Hash de contraseñas y tokens firmados |
| Despliegue | Render + MongoDB Atlas | Gratis y conectado a GitHub |

## Arquitectura

```text
┌─────────────────────────────┐
│          FLUTTER            │   Android + Web
│  auth (A)   ·   agenda (B)  │
└──────────────┬──────────────┘
               │ HTTP/REST + Authorization: Bearer <token>
┌──────────────▼──────────────┐
│     NODE.JS + EXPRESS       │   API REST
│ /api/auth (A) /api/tasks (B)│
└──────────────┬──────────────┘
               │ Mongoose
┌──────────────▼──────────────┐
│       MONGODB ATLAS         │
│   usuarios  ──►  tareas     │   cada tarea guarda el userId de su dueño
└─────────────────────────────┘
```

El frontend sigue **Clean Architecture**. Cada funcionalidad tiene tres capas:

```text
presentation   pantallas y estado (provider)
     │
   domain      entidades, contratos y casos de uso — sin Flutter ni HTTP
     │
    data       modelos JSON, llamadas a la API y almacenamiento
```

La regla: `domain` no depende de nadie. Si mañana se cambia la librería HTTP, solo se toca `data`.

## Estructura del proyecto

```text
gestor-agenda/
├── backend/                     API REST
│   ├── src/
│   │   ├── config/              variables de entorno y conexión a MongoDB
│   │   ├── models/              user.model.js (A) · task.model.js (B)
│   │   ├── controllers/         auth.controller.js (A) · task.controller.js (B)
│   │   ├── routes/              auth.routes.js (A) · task.routes.js (B)
│   │   ├── middlewares/         verificación del token y manejo de errores
│   │   ├── utils/               validaciones, JWT y códigos de recuperación
│   │   └── app.js               arma Express y registra las rutas
│   ├── tests/                   pruebas de la API
│   ├── server.js                arranque local y en Render
│   └── .env.example             plantilla de variables (sin secretos)
│
├── frontend/                    app Flutter (solo Android y Web)
│   └── lib/
│       ├── core/                tema, colores, validadores y ApiClient compartido
│       ├── features/auth/       login, registro, recuperación, perfil   (A)
│       ├── features/agenda/     lista de tareas y formulario            (B)
│       ├── app/                 rutas y AuthGate (decide login o agenda)
│       └── main.dart            conecta todas las piezas
│
├── render.yaml                  despliegue de los dos servicios
└── DEPLOY_RENDER.md             paso a paso del despliegue
```

## Instalación

Necesitas **Flutter 3.47+**, **Node.js 22+**, **Git** y una cuenta gratuita de **MongoDB Atlas**.

```bash
git clone https://github.com/sanperex/gestor-agenda.git
```

```bash
cd gestor-agenda/backend && npm install
```

```bash
cd ../frontend && flutter pub get
```

## Configuración: variables de entorno

Copia `backend/.env.example` a `backend/.env` y llena los valores. **El archivo `.env` nunca se sube a GitHub.**

| Variable | Para qué | Ejemplo |
|---|---|---|
| `MONGODB_URI` | Conexión a Atlas, con el nombre de la base al final | `mongodb+srv://usuario:clave@cluster0.xxxx.mongodb.net/gestor_agenda` |
| `JWT_SECRET` | Clave con la que se firman los tokens | cadena larga y aleatoria |
| `JWT_EXPIRES_IN` | Duración del token | `7d` |
| `PORT` | Puerto local (en Render lo pone el sistema) | `3000` |
| `CORS_ORIGIN` | Orígenes permitidos | `*` |
| `RESET_CODE_DEMO` | `true` devuelve el código de recuperación en la respuesta (solo demo académica) | `true` |

Generar un `JWT_SECRET`:

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

En MongoDB Atlas hay que permitir el acceso desde `0.0.0.0/0` en **Network Access**, porque Render no tiene IP fija.

## Ejecución

Backend, desde la carpeta `backend`:

```bash
npm run dev
```

Queda en `http://localhost:3000`. Se comprueba abriendo `http://localhost:3000/api/health`.

Frontend, desde la carpeta `frontend`:

```bash
flutter run -d edge
```

```bash
flutter run -d emulator-5554
```

En el emulador de Android la app usa `http://10.0.2.2:3000`, que es como el emulador ve tu PC.

Para apuntar la app a la API ya publicada:

```bash
flutter run --dart-define=API_URL=https://gestor-agenda-api.onrender.com
```

Pruebas:

```bash
cd frontend && flutter test
```

```bash
cd backend && npm run test:tasks
```

## Endpoints

Todas las respuestas tienen el mismo formato:

```json
{ "success": true,  "message": "Sesión iniciada", "data": {} }
{ "success": false, "message": "Correo o contraseña incorrectos" }
```

### Autenticación — Aprendiz A

| Método | Ruta | Cuerpo | Respuesta |
|---|---|---|---|
| POST | `/api/auth/register` | `name`, `email`, `password` | 201 · usuario y token |
| POST | `/api/auth/login` | `email`, `password` | 200 · usuario y token |
| GET | `/api/auth/me` | _(token)_ | 200 · usuario actual |
| POST | `/api/auth/forgot-password` | `email` | 200 · genera un código de 6 dígitos |
| POST | `/api/auth/reset-password` | `email`, `code`, `newPassword` | 200 · contraseña cambiada |
| GET | `/api/health` | — | 200 · estado de la API y de la base |

Errores: `400` datos inválidos · `401` credenciales o token incorrectos · `409` correo repetido · `429` demasiados intentos.

### Tareas — Aprendiz B

Todas requieren la cabecera `Authorization: Bearer <token>`.

| Método | Ruta | Cuerpo / filtros | Respuesta |
|---|---|---|---|
| GET | `/api/tasks` | `?status=` `&search=` | 200 · lista de tareas |
| GET | `/api/tasks/summary` | — | 200 · totales por estado |
| GET | `/api/tasks/:id` | — | 200 · una tarea |
| POST | `/api/tasks` | `title`, `dueDate`, `description?`, `location?`, `status?`, `priority?` | 201 · tarea creada |
| PUT | `/api/tasks/:id` | los campos a cambiar | 200 · tarea actualizada |
| DELETE | `/api/tasks/:id` | — | 200 · tarea eliminada |

## MongoDB

Base de datos `gestor_agenda`, con dos colecciones:

**`usuarios`** (Aprendiz A)

| Campo | Notas |
|---|---|
| `_id` | Identificador que crea MongoDB. Es el `userId` que usan las tareas |
| `name`, `email` | El correo es único y se guarda en minúsculas |
| `password` | **Hash de bcrypt.** Nunca se guarda ni se devuelve la contraseña real |
| `resetCodeHash`, `resetCodeExpires`, `resetAttempts` | Recuperación: el código también va con hash, vence a los 15 minutos y admite 5 intentos |
| `createdAt`, `updatedAt` | Automáticos |

**`tareas`** (Aprendiz B)

| Campo | Notas |
|---|---|
| `userId` | Apunta al usuario dueño. Lo pone el servidor a partir del token, nunca el cliente |
| `title`, `description`, `dueDate`, `location` | Datos de la tarea |
| `status` | `pending`, `inProgress` o `completed` |
| `priority` | `low`, `medium` o `high` |

Cada consulta filtra por `userId`, así que un usuario no puede ver ni modificar tareas de otro.

## Autenticación con JWT

1. Al registrarse o iniciar sesión, el servidor devuelve un **token** firmado con `JWT_SECRET`.
2. Flutter lo guarda cifrado en el dispositivo (`flutter_secure_storage`).
3. El `ApiClient` lo agrega solo en cada petición: `Authorization: Bearer <token>`.
4. El middleware del backend lo verifica y deja el id del usuario listo para los controladores.
5. Cerrar sesión es borrar el token del dispositivo. El token vence a los 7 días.

El token es como un carné sellado: cualquiera puede leerlo, pero nadie puede falsificarlo sin la clave del servidor.

## GitFlow

```text
main       ●────────────●────────────●     entregas estables (lo que está desplegado)
develop    ●──────●─────●──────●           integración del trabajo de los dos
feature/*     ●──●         ●──●            una rama por tarea
```

- Nadie programa directo sobre `main`.
- Cada funcionalidad sale de `develop` en su propia rama `feature/...`.
- Al terminar se abre un **Pull Request**, el compañero lo revisa y se fusiona.
- Ramas usadas: `feature/auth-backend`, `feature/auth-frontend`, `feature/agenda`, `feature/deploy-render`.

Mensajes de commit: `feat:` funcionalidad nueva · `fix:` arreglo · `docs:` documentación · `chore:` configuración.

## Despliegue

El archivo [`render.yaml`](render.yaml) describe los dos servicios de Render (la API y la app web), y
[`DEPLOY_RENDER.md`](DEPLOY_RENDER.md) trae el paso a paso completo, incluida la configuración de MongoDB Atlas.

En resumen: Render lee `render.yaml`, crea los servicios, pide `MONGODB_URI` y `API_URL`, y cada vez que
se fusiona algo a `main` vuelve a desplegar solo.

## Evidencias

_(guardar las capturas en `docs/evidencias/` y enlazarlas aquí)_

- [ ] Registro e inicio de sesión desde la app
- [ ] Recuperación de contraseña
- [ ] Lista de tareas: crear, editar y completar
- [ ] Perfil del usuario
- [ ] Colección `usuarios` en Atlas, con la contraseña guardada como hash
- [ ] Colección `tareas` en Atlas, con su `userId`
- [ ] Pruebas de la API en Thunder Client o Postman
- [ ] `flutter test` en verde
- [ ] Pull Requests del repositorio
- [ ] Servicios desplegados en Render
