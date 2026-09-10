import '../repositories/auth_repository.dart';

/// Caso de uso: cambiar la contrasena usando el codigo recibido.
class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call({required String email, required String code, required String newPassword}) {
    return _repository.resetPassword(email: email, code: code, newPassword: newPassword);
  }
}
