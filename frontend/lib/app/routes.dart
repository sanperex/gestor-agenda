import 'package:flutter/material.dart';

import '../features/agenda/domain/entities/task.dart';
import '../features/agenda/presentation/pages/task_form_page.dart';
import '../features/auth/presentation/pages/forgot_pass_page.dart';
import '../features/auth/presentation/pages/profile_page.dart';
import '../features/auth/presentation/pages/register_page.dart';

/// Rutas con nombre de la app (archivo COMPARTIDO).
/// La pantalla inicial no esta aqui: la decide AuthGate segun la sesion.
class AppRoutes {
  AppRoutes._();

  // Aprendiz A
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Aprendiz B
  static const String taskForm = '/task-form'; // argumento opcional: la Task a editar
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
        register: (_) => const RegisterPage(),
        forgotPassword: (_) => const ForgotPassPage(),
        taskForm: (context) => TaskFormPage(task: ModalRoute.of(context)?.settings.arguments as Task?),
        profile: (_) => const ProfilePage(),
      };
}
