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
- Falta: instalar API 36 + NDK, recompilar; luego esqueleto backend.
