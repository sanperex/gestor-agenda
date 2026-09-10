import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: crear una cuenta (y quedar con la sesion iniciada).
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String name, required String email, required String password}) {
    return _repository.register(name: name, email: email, password: password);
  }
}
