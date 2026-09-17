# Bitacora

## 2026-09-10
- Hecho: Fase 0 (analisis). Usuario acepto todas las recomendaciones. Plan: montar A primero, B despues.
- Archivos: `.claude/CLAUDE.md`, `.claude/decisiones/001-stack-y-arquitectura.md`, `.claude/docs/ruta.md`, esta bitacora.
- Hallazgo: Node 24, npm 11, Git 2.55 OK. Flutter SI esta en PATH: `C:\Users\User\flutter-sdk\flutter\bin` (falta confirmar con flutter doctor).
- F1: Flutter 3.47.1 stable OK. cmdline-tools/latest instalado. Existe sdk/licenses/android-sdk-license.
  Doctor sigue diciendo "license status unknown": las cmdline-tools nuevas cambiaron sdkmanager por "android sdk"
  y Flutter aun pregunta a la antigua. Se verifica de verdad compilando en F4.
- Chrome no instalado -> web se prueba con Edge (`-d edge`). Visual Studio no se necesita.
- VS Code 1.136 con extensiones Dart y Flutter. Sin emulador Android creado.
- Emulador Pixel_8 creado. F1 cerrada. Atlas se crea en F5 y Thunder Client en F7 (cuando se usen).
- Git sin user.name/user.email global. gh CLI no instalado (GitHub se usa por la web).
- F2: git config (sanperex / perexgames2@gmail.com, rama por defecto main). Repo: https://github.com/sanperex/gestor-agenda
- `.gitignore` creado. git init + remote origin. Commit 69e0cc2 "chore: initial project setup" subido a main.
- No se pudo abrir PR: main es la unica rama (no hay rama destino) y gh CLI no esta instalado.
- develop creada y subida. Rama actual: feature/project-setup.
- F4: `flutter create --platforms=android,web --org com.sanperex --project-name gestor_agenda frontend`.
  Carpetas Clean Architecture creadas (con .gitkeep) + `features/agenda/README.md` para B.
- ERROR `flutter build apk --debug`: Gradle intenta autoinstalar piezas faltantes con sdkmanager.bat
  (cmdline-tools 23.0) y este se cae (0xC0000409). Faltan: plataforma android-36 (solo hay 37)
  y NDK 28.2.13676358 (lo pide Flutter 3.47). Solucion: instalarlas desde Android Studio SDK Manager.
- API 36 + NDK instalados con `android sdk install` (cmdline-tools nuevas). APK debug compila OK.
- Usuario pidio: "haz todo, yo solo configuro Mongo". Se construyo toda la parte A:
  - Rama feature/auth-backend: backend Express 5 + Mongoose 9 (config, models, controllers, routes,
    middlewares, utils). Prueba 21/21 con mongodb-memory-server (script en scratchpad, no en repo).
  - Rama feature/auth-frontend: http, provider, flutter_secure_storage. core (ApiClient, tema, validadores),
    features/auth (domain/data/presentation), lib/app (AuthGate, rutas, placeholder agenda), main.dart.
    AndroidManifest: INTERNET en main; cleartext solo en debug. 17 tests OK. flutter analyze sin issues.
  - Prueba real en web (build web + backend): registro OK, CORS OK, sesion persiste al recargar.
- Nota: hay un mongod local escuchando en 127.0.0.1:27017 (no lo inicio Claude). Sirve para desarrollo local.
- Falta: MONGODB_URI (usuario), PRs, Railway, README, prueba en emulador Android.
- Atlas: cluster0.hs7qeez, base gestor_agenda, coleccion "usuarios" (creada por el usuario).
  Modelo User apunta a "usuarios". MONGODB_URI puesta en backend/.env por el usuario. Backend conecta OK.
- ERROR: `node --watch` reiniciaba el server a mitad de peticion (Windows marca cambios falsos en
  node_modules) -> ECONNRESET. Fix: `--watch-path=src --watch-path=server.js` en script dev.
- Pruebas contra Atlas: 12/12 OK. Usuario de prueba: prueba549219@gestor.com / nueva456.
- Commit f7f658c en feature/auth-backend, mergeado a feature/auth-frontend. Ambas subidas.
- Usuario probo la app contra el backend con Atlas: funciona.
- PRs #1 (auth-backend) y #2 (auth-frontend) se fusionaron a MAIN (GitHub usa main como destino por
  defecto). develop se adelanto a main con fast-forward (`git fetch origin main:develop`), sin perder nada.
  Pendiente: usuario cambia la rama por defecto de GitHub a develop.
- Falta: Railway, README.

## 2026-09-16
- Usuario pidio desplegar en Vercel (no Railway). Rama feature/deploy-vercel.
- Nuevo: backend/api/index.js (funcion serverless, cachea la conexion) y backend/vercel.json
  (reescribe todo a /api). db.js: maxPoolSize 5. server.js sigue siendo el arranque local.
- Probado con un simulador local (http server llamando al handler) contra Atlas: 12/12 OK.
- Decision documentada en decisiones/002-despliegue-vercel.md.
- Falta: usuario crea los 2 proyectos en Vercel (backend desde GitHub, frontend con CLI), variables
  de entorno, rebuild del frontend con --dart-define=API_URL, README.
- Cambio de plataforma: el backend va a RENDER (no Vercel). Rama feature/deploy-render desde main.
  Nuevo `render.yaml` (rootDir backend, npm ci / npm start, healthCheckPath /api/health,
  MONGODB_URI y JWT_SECRET con sync:false). No hizo falta tocar el codigo del backend.
  ApiClient: timeout 15 s -> 40 s por el "sueno" del plan gratis de Render.
  Decision en decisiones/003-despliegue-render.md. Los archivos de Vercel se quedan como alternativa.
- API en Render OK: https://gestor-agenda-api.onrender.com (health 200, db conectada). 10/12 pruebas;
  las 2 que fallan son porque falta RESET_CODE_DEMO=true en el panel de Render (no es bug).
- HALLAZGO: el PR #3 (feature/agenda, Aprendiz B) se fusiono a main y luego el PR #9 lo REVIRTIO.
  Por eso main tenia solo la parte A. El trabajo de B estaba intacto en origin/feature/agenda.
  Arreglo: rama restore/agenda = revert del revert (commit "Reapply..."). Conflicto solo en render.yaml:
  se conservo la version de B (define API + sitio estatico web con render-build.sh).
  Verificado junto: flutter analyze sin issues y 38 tests OK (17 de A + 21 de B).
- Aviso de seguridad dado al usuario: la contrasena de Atlas quedo visible en una captura del chat;
  se le pidio rotarla en Database Access y actualizar .env y Render.
