# 003 — Despliegue en Render (2026-09-16)

## Para que sirve
El usuario cambio de Vercel a Render. Aqui queda como y que implica.

## Decision
| Parte | Donde | Como |
|---|---|---|
| Backend | Render, Web Service, Root Directory `backend` | proceso normal: `npm start` -> `server.js` |
| Frontend | pendiente (Render Static Site o Vercel) | `flutter build web` + subir `frontend/build/web` |
| Base de datos | MongoDB Atlas (sin cambio) | Network Access ya permite 0.0.0.0/0 |

## Por que Render es mas simple que Vercel aqui
Render ejecuta el servidor como proceso permanente, igual que en local:
- `server.js` sirve tal cual. No hace falta `api/index.js` ni `vercel.json`.
- `PORT` lo inyecta Render y `env.js` ya lo lee.
- `app.listen(port)` escucha en todas las interfaces, que es lo que Render necesita.
- Los `console.log` (ej. el codigo de recuperacion) se ven en la pestana Logs.

## Contra del plan gratis
El servicio se duerme tras ~15 min sin trafico; la siguiente peticion puede tardar ~50 s.
Por eso el timeout del ApiClient en Flutter subio de 15 s a 40 s.

## Archivos
- `render.yaml` en la raiz: blueprint con build/start, healthCheckPath y variables.
  MONGODB_URI y JWT_SECRET van con `sync: false` -> se escriben en el panel, nunca en el repo.
- Lo de Vercel (`backend/api/index.js`, `backend/vercel.json`) se queda en el repo: no estorba
  y sirve de alternativa. Si se quiere limpiar, se borran esos dos archivos.
