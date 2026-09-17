import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Marco comun de las pantallas de auth: icono, titulo, subtitulo y una tarjeta con el formulario.
/// El ancho maximo evita que en la web el formulario ocupe toda la pantalla.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.event_note_rounded,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: showBackButton ? AppBar(backgroundColor: Colors.transparent) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.info,
                    child: Icon(icon, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(padding: const EdgeInsets.all(20), child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
