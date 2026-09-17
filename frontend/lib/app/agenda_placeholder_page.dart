import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

/// Pantalla TEMPORAL despues del login, hasta que el Aprendiz B entregue la agenda.
/// Sirve para probar el flujo completo: login -> usuario autenticado -> logout.
class AgendaPlaceholderPage extends StatelessWidget {
  const AgendaPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi agenda'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_available_rounded, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Hola, ${user?.name ?? ''}', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              const Text(
                'Sesión iniciada correctamente.\nAquí irá la agenda (módulo del Aprendiz B).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
