import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: al abrir la app, saber si ya hay una sesion iniciada.
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<User?> call() => _repository.getCurrentUser();
}
