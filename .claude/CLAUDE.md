# Gestor de Agenda — Taller 3 (Flutter)

## Que es
App de agenda. Flutter (Android + Web) -> API REST Node.js + Express -> MongoDB.
Proyecto academico en pareja:
- Aprendiz A (este usuario, GitHub `sanperex`): autenticacion, usuarios, JWT, integracion auth, despliegue.
- Aprendiz B: agenda/tareas (lista, formulario, perfil, CRUD de tasks). Monta su parte DESPUES sobre este repo.

## Forma de trabajo
Claude construye la parte A y explica en corto. El usuario configura MongoDB y revisa.
No hacer la parte de B. Nada destructivo ni merge a main sin preguntar.

## Donde esta cada cosa
- `backend/`  Express 5 + Mongoose 9. Rutas en `src/routes`, logica en `src/controllers`.
- `frontend/` Flutter 3.47 (Android + Web). Clean Architecture en `lib/features/auth`.
- `frontend/lib/app/` rutas, AuthGate (decide login/agenda) y pantalla temporal de agenda.
- Contrato A<->B: `docs/api-contract.md`. Decisiones: `decisiones/`. Ruta: `docs/ruta.md`.

## Como se corre
Backend (necesita `backend/.env` con MONGODB_URI y JWT_SECRET; guia en `.env.example`):
```
cd backend
npm install
npm run dev        # http://localhost:3000/api/health
```
Frontend:
```
cd frontend
flutter pub get
flutter run -d edge          # web (no hay Chrome; Edge funciona)
flutter run -d emulator-5554 # Android (emulador Pixel_8); usa http://10.0.2.2:3000
flutter run --dart-define=API_URL=https://<api>.vercel.app   # apuntar a la API desplegada
flutter test                 # 17 pruebas
```

## Estado actual (2026-09-10)
- Backend auth completo y probado (21/21 casos con MongoDB en memoria).
- Flutter auth completo: login, registro, recuperacion (2 pasos), sesion guardada, logout. 17 tests OK.
- Probado de punta a punta en web: registro -> agenda -> recargar mantiene sesion.
- Falta: despliegue en Vercel (backend serverless + web) y README con links.
