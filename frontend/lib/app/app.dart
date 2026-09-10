import 'package:flutter/material.dart';

import '../core/constants/app_theme.dart';
import 'auth_gate.dart';
import 'routes.dart';

class GestorAgendaApp extends StatelessWidget {
  const GestorAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Agenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
      routes: AppRoutes.routes,
    );
  }
}
