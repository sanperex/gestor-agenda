import '../repositories/auth_repository.dart';

/// Caso de uso: cerrar sesion (borra el token del dispositivo).
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
