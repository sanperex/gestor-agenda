import '../entities/forgot_password_result.dart';
import '../entities/user.dart';

/// Contrato: QUE se puede hacer con la autenticacion, sin decir COMO.
/// La implementacion real (API + almacenamiento) esta en data/repositories.
abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register({required String name, required String email, required String password});

  /// Recupera la sesion guardada en el dispositivo. Devuelve null si no hay sesion valida.
  Future<User?> getCurrentUser();

  Future<ForgotPasswordResult> forgotPassword({required String email});

  /// Devuelve el mensaje de exito de la API.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> logout();
}
