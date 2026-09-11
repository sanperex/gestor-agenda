import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/task_summary.dart';
import '../providers/task_provider.dart';
import '../widgets/status_badge.dart';

/// Perfil del usuario (Aprendiz B).
/// Los datos salen del AuthProvider del Aprendiz A (que los trae de GET /api/auth/me),
/// y el resumen de tareas del TaskProvider.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Tendrás que volver a ingresar con tu correo y contraseña.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Como indica AuthProvider: primero se cierran las pantallas de encima, para que
    // AuthGate (la de abajo) pueda mostrar el login.
    Navigator.of(context).popUntil((route) => route.isFirst);
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final summary = context.select<TaskProvider, TaskSummary>((p) => p.summary);
    final name = user?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.info,
                child: Text(
                  _initials(name),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              user?.email ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mis tareas', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Stat(label: 'Total', value: summary.total, color: AppColors.primary),
                        _Stat(label: 'Pendientes', value: summary.pending, color: TaskColors.pending),
                        _Stat(label: 'En progreso', value: summary.inProgress, color: AppColors.primary),
                        _Stat(label: 'Hechas', value: summary.completed, color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Nombre'),
                    subtitle: Text(name),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Correo'),
                    subtitle: Text(user?.email ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Ana María Torres" -> "AM". Nunca falla con un nombre vacio.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final initials = parts.map((p) => p[0].toUpperCase()).join();
    return initials.isEmpty ? '?' : initials;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
