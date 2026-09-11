import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/forgot_password_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementacion real del contrato: junta la API (remote) con el token guardado (local).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this._remote, required this._local});

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<User> login({required String email, required String password}) async {
    final session = await _remote.login(email: email, password: password);
    await _local.saveToken(session.token);
    return session.user;
  }

  @override
  Future<User> register({required String name, required String email, required String password}) async {
    final session = await _remote.register(name: name, email: email, password: password);
    await _local.saveToken(session.token);
    return session.user;
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _local.readToken();
    if (token == null) return null;
    try {
      return await _remote.me();
    } on AppException catch (e) {
      // Token vencido o usuario borrado: se limpia la sesion.
      if (e.statusCode == 401 || e.statusCode == 404) {
        await _local.deleteToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ForgotPasswordResult> forgotPassword({required String email}) {
    return _remote.forgotPassword(email: email);
  }

  @override
  Future<String> resetPassword({required String email, required String code, required String newPassword}) {
    return _remote.resetPassword(email: email, code: code, newPassword: newPassword);
  }

  @override
  Future<void> logout() => _local.deleteToken();
}
