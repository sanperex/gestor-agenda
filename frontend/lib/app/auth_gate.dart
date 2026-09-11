import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/agenda/presentation/pages/agenda_list_page.dart';

/// "Portero" de la app: muestra una pantalla u otra segun el estado de la sesion.
/// Al iniciar o cerrar sesion, cambia solo; las pantallas no navegan a mano.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

    return switch (status) {
      AuthStatus.checking => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.unauthenticated => const LoginPage(),
      AuthStatus.authenticated => const AgendaListPage(), // Aprendiz B
    };
  }
}
