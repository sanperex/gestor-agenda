import '../entities/forgot_password_result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: pedir un codigo para recuperar la contrasena.
class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<ForgotPasswordResult> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
