import 'package:flutter/foundation.dart';

/// Direcciones de la API.
///
/// La URL base se puede cambiar al compilar, sin tocar el codigo:
/// `flutter run --dart-define=API_URL=https://mi-api.up.railway.app`
class ApiConstants {
  ApiConstants._();

  static const String _apiUrlFromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_apiUrlFromEnv.isNotEmpty) return _apiUrlFromEnv;
    // En el emulador de Android "localhost" es el propio celular; 10.0.2.2 es el PC.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // 40 s: en el plan gratis de Render el servidor se duerme y la primera peticion tarda.
  static const Duration timeout = Duration(seconds: 40);

  // Autenticacion (Aprendiz A)
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // Tareas (Aprendiz B): agregar aqui, ej. static const String tasks = '/api/tasks';
}
