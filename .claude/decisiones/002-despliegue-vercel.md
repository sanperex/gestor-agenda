# 002 — Despliegue en Vercel (2026-09-16)

## Para que sirve
El usuario pidio desplegar en Vercel en vez de Railway. Aqui queda el como y el por que.

## Decision
| Parte | Donde | Como |
|---|---|---|
| Backend (Express) | Vercel, proyecto con Root Directory = `backend` | funcion serverless en `backend/api/index.js` |
| Frontend (Flutter Web) | Vercel, proyecto aparte | `flutter build web` local + `vercel deploy --prod` desde `frontend/build/web` |
| Base de datos | MongoDB Atlas (sin cambio) | Network Access ya permite 0.0.0.0/0 |

## Diferencia con Railway
Railway deja el proceso encendido. Vercel lo enciende por peticion (serverless):
- La primera peticion despues de un rato tarda 1-2 s (arranque en frio).
- `server.js` NO se usa en Vercel; solo en local. Vercel llama a `api/index.js`.
- La conexion de Mongoose se guarda en una variable del modulo para reusarla mientras la
  instancia siga "caliente"; si la conexion falla se limpia para reintentar.
- `maxPoolSize: 5` porque puede haber varias instancias pequenas a la vez.
- `vercel.json` reescribe TODAS las rutas a `/api`, para que Express siga viendo `/api/auth/...`.

## Por que Flutter Web no se construye en Vercel
Vercel no trae Flutter. Se podria descargar el SDK en cada build, pero es lento y fragil.
Se construye en el PC y se sube el resultado (`build/web`), que es HTML+JS estatico.
Como la URL de la API se fija al compilar, cada vez que cambie hay que reconstruir:
`flutter build web --release --dart-define=API_URL=https://<backend>.vercel.app`

## Variables de entorno en Vercel (proyecto backend)
MONGODB_URI, JWT_SECRET, JWT_EXPIRES_IN, CORS_ORIGIN, RESET_CODE_DEMO.
PORT no se usa: lo maneja Vercel.
