# Desplegar en Render

El proyecto se despliega en **dos servicios de Render** más la base de datos en **MongoDB Atlas**:

| Qué | Tipo en Render | Carpeta | URL de ejemplo |
|---|---|---|---|
| API (Express) | Web Service (Node) | `backend/` | `https://gestor-agenda-api.onrender.com` |
| App web (Flutter) | Static Site | `frontend/` | `https://gestor-agenda-web.onrender.com` |

Todo está descrito en [`render.yaml`](render.yaml) (Blueprint), así que Render crea los dos servicios de una vez.

---

## 1. Antes de empezar

1. **La rama a desplegar tiene todo el código.** Render despliega desde una rama de GitHub (normalmente `main`). Unir antes los PR pendientes, incluido el de la agenda (`feature/agenda` → `develop` → `main`).
2. **MongoDB Atlas** (cloud.mongodb.com):
   - Crear un clúster gratuito **M0**.
   - **Database Access:** crear un usuario con contraseña.
   - **Network Access:** agregar `0.0.0.0/0`. Render no tiene IP fija; sin esto la API no puede conectarse.
   - **Connect → Drivers:** copiar la cadena y poner el nombre de la base después de `.net/`:
     ```
     mongodb+srv://USUARIO:CONTRASENA@cluster0.xxxxx.mongodb.net/gestor_agenda?retryWrites=true&w=majority
     ```
     Si la contraseña tiene caracteres como `@`, `:` o `/`, hay que codificarlos (por ejemplo `@` → `%40`).

## 2. Crear los servicios (Blueprint)

1. En Render: **New → Blueprint** y conectar el repositorio `sanperex/gestor-agenda`.
2. Elegir la rama (`main`). Render lee `render.yaml` y muestra los dos servicios.
3. Render pide las variables marcadas para escribir a mano:

   | Servicio | Variable | Valor |
   |---|---|---|
   | `gestor-agenda-api` | `MONGODB_URI` | la cadena de Atlas del paso 1 |
   | `gestor-agenda-web` | `API_URL` | `https://gestor-agenda-api.onrender.com` (sin `/` al final) |

   `JWT_SECRET` lo genera Render solo. `JWT_EXPIRES_IN`, `CORS_ORIGIN` y `RESET_CODE_DEMO` ya vienen puestos.
4. **Apply.** La API tarda 1–2 minutos. La app web tarda unos 5 minutos la primera vez, porque descarga Flutter y compila.

> Si el nombre `gestor-agenda-api` ya estaba ocupado, Render le agrega un sufijo a la URL. En ese caso, copiar la URL real de la API (arriba en su página), ponerla en `API_URL` del sitio web y hacer **Manual Deploy → Deploy latest commit** del sitio web. La URL queda fija dentro de la app al compilar, así que cambiar la variable sin volver a desplegar no sirve.

## 3. Comprobar la API

Abrir `https://<tu-api>.onrender.com/api/health`. Debe responder:

```json
{ "success": true, "message": "API funcionando", "data": { "db": "conectada" } }
```

Si el despliegue falla con `No se pudo conectar a MongoDB`, revisar `MONGODB_URI` y el `0.0.0.0/0` de Atlas.

## 4. Comprobar la app web

Abrir `https://<tu-web>.onrender.com`, registrarse, crear una tarea, recargar la página (la sesión se mantiene) y cerrar sesión.

## 5. Cerrar CORS (recomendado)

Con todo funcionando, en `gestor-agenda-api` → **Environment**, cambiar `CORS_ORIGIN` de `*` a la URL de la app web:

```
https://gestor-agenda-web.onrender.com
```

Render reinicia la API sola. Para permitir varios orígenes, separarlos con comas.

---

## Cosas a saber del plan gratuito

- **La API se duerme** tras 15 minutos sin uso, y despertarla tarda unos 50 segundos. La app espera como máximo 15 segundos por respuesta, así que **antes de una demo abrir `/api/health`** y esperar a que responda. Si no, el primer inicio de sesión puede dar error de tiempo agotado; basta con volver a intentar.
- El sitio estático no se duerme.

## Si algo falla

| Síntoma | Causa probable |
|---|---|
| El build del sitio web falla con `falta la variable de entorno API_URL` | No se puso `API_URL` en `gestor-agenda-web`. |
| La app abre, pero al iniciar sesión dice que no hay conexión | `API_URL` apunta mal, o la API está dormida (ver arriba). |
| En la consola del navegador aparece un error de CORS | `CORS_ORIGIN` no incluye la URL exacta de la app web (con `https://`, sin `/` final). |
| La API no arranca: `Falta la variable de entorno MONGODB_URI` | Falta la variable en `gestor-agenda-api`. |

## Sin Blueprint (a mano)

Si se prefiere crear los servicios uno por uno:

- **API:** New → Web Service → repositorio. Root Directory `backend`, Build `npm ci`, Start `npm start`, Health Check Path `/api/health`. Variables: `MONGODB_URI`, `JWT_SECRET` (clave larga aleatoria), `JWT_EXPIRES_IN=7d`, `CORS_ORIGIN=*`, `RESET_CODE_DEMO=true`, `NODE_VERSION=22`.
- **Web:** New → Static Site → repositorio. Root Directory `frontend`, Build `bash render-build.sh`, Publish Directory `build/web`. Variable: `API_URL`. En **Redirects/Rewrites** agregar `/*` → `/index.html` (Rewrite).

## Probar el build web en un PC

Con Flutter instalado, desde `frontend/` (en Git Bash o Linux/macOS):

```bash
API_URL=http://localhost:3000 bash render-build.sh
```
