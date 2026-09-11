import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/forgot_password_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

/// Estado de autenticacion de toda la app.
///
/// Las pantallas escuchan: [status], [user], [isLoading] y [errorMessage].
/// Aprendiz B: usar `context.watch<AuthProvider>().user` en el Perfil
/// y `context.read<AuthProvider>().logout()` para cerrar sesion.
class AuthProvider extends ChangeNotifier {
  // "this._login" crea el parametro con nombre "login" y lo guarda en el campo privado _login.
  AuthProvider({
    required this._login,
    required this._register,
    required this._getCurrentUser,
    required this._forgotPassword,
    required this._resetPassword,
    required this._logout,
  });

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final GetCurrentUserUseCase _getCurrentUser;
  final ForgotPasswordUseCase _forgotPassword;
  final ResetPasswordUseCase _resetPassword;
  final LogoutUseCase _logout;

  AuthStatus _status = AuthStatus.checking;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Al abrir la app: si hay un token guardado y sigue valido, entra directo.
  Future<void> checkSession() async {
    try {
      _user = await _getCurrentUser();
    } catch (_) {
      _user = null; // sin conexion u otro error: se pide login
    }
    _status = _user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    final user = await _run(() => _login(email: email, password: password));
    if (user == null) return false;
    _setAuthenticated(user);
    return true;
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    final user = await _run(() => _register(name: name, email: email, password: password));
    if (user == null) return false;
    _setAuthenticated(user);
    return true;
  }

  /// Devuelve null si fallo (el motivo queda en [errorMessage]).
  Future<ForgotPasswordResult?> forgotPassword({required String email}) {
    return _run(() => _forgotPassword(email: email));
  }

  /// Devuelve el mensaje de exito, o null si fallo.
  Future<String?> resetPassword({required String email, required String code, required String newPassword}) {
    return _run(() => _resetPassword(email: email, code: code, newPassword: newPassword));
  }

  /// Si hay pantallas abiertas encima (ej. Perfil), cerrarlas antes con
  /// `Navigator.of(context).popUntil((r) => r.isFirst)`.
  Future<void> logout() async {
    await _logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setAuthenticated(User user) {
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Ejecuta una accion manejando carga y errores en un solo lugar.
  Future<T?> _run<T>(Future<T> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on AppException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      debugPrint('Error inesperado: $e');
      _errorMessage = 'Ocurrió un error inesperado';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
