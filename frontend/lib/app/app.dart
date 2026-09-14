import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/constants/app_theme.dart';
import '../core/widgets/mobile_frame.dart';
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
      // Vista de celular también desde la web (Aprendiz B): ver core/widgets/mobile_frame.dart.
      builder: (context, child) => MobileFrame(child: child ?? const SizedBox.shrink()),
      // Sin esto el calendario y el reloj del formulario de tareas salen en ingles.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
