import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/forgot_pass_page.dart';
import '../features/auth/presentation/pages/register_page.dart';

/// Rutas con nombre de la app (archivo COMPARTIDO).
/// La pantalla inicial no esta aqui: la decide AuthGate segun la sesion.
class AppRoutes {
  AppRoutes._();

  // Aprendiz A
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Aprendiz B: agregar aqui sus rutas, ej. '/task-form', '/profile'.

  static Map<String, WidgetBuilder> get routes => {
        register: (_) => const RegisterPage(),
        forgotPassword: (_) => const ForgotPassPage(),
      };
}
