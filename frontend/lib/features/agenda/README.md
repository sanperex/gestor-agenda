# features/agenda — Aprendiz B

Esta carpeta es del **Aprendiz B**: lista de agenda, formulario de tarea, perfil y CRUD de tareas.
El Aprendiz A no programa aqui.

## Estructura esperada (igual que auth)
- `data/`         datasources, models, repositories (implementacion)
- `domain/`       entities, repositories (contratos), usecases
- `presentation/` pages, providers, widgets

## Lo que A deja listo para B
- `core/network/api_client.dart`: cliente HTTP que agrega el token solo (`Authorization: Bearer ...`).
- `AuthProvider` (features/auth): usuario actual y `logout()` para el Perfil.
- Endpoint `GET /api/auth/me` para los datos del Perfil.
- Ruta `/agenda`: a donde navega la app despues de un login exitoso.

Guia completa (backend y Flutter): `.claude/docs/api-contract.md`.
