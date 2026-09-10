import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: iniciar sesion.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}
