import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/vivid_backdrop.dart';
import '../../../agenda/domain/entities/task_summary.dart';
import '../../../agenda/presentation/providers/task_provider.dart';
import '../../../agenda/presentation/widgets/agenda_bottom_bar.dart';
import '../providers/auth_provider.dart';

/// Perfil del usuario — pantalla del APRENDIZ B.
///
/// Vive en features/auth/ porque ahi la ubica la estructura del taller
/// ("profile_page.dart (Aprendiz B)" dentro de auth/presentation/pages).
/// Los datos salen del AuthProvider del Aprendiz A (que los trae de GET /api/auth/me),
/// y el resumen de tareas del TaskProvider de la agenda.
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
            style: TextButton.styleFrom(foregroundColor: Vivid.red),
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
    final media = MediaQuery.of(context);
    final percent = summary.total == 0 ? 0 : (summary.completed * 100 / summary.total).round();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Vivid.lavender,
        // StackFit.expand: sin esto el Stack mide lo que su contenido, y con pocos datos o una
        // pantalla alta la barra inferior queda flotando a media pantalla en vez de abajo.
        body: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 130 + media.padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      // Termina 2 px antes del borde: la hoja lavanda lo tapa igual, y así no
                      // asoma una línea índigo cuando el marco se escala a un tamaño fraccionario.
                      const Positioned.fill(bottom: 2, child: VividBackdrop()),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 30,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Vivid.lavender,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, media.padding.top + 12, 20, 54),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 44,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Mi perfil',
                                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Entrance(
                              child: Container(
                                width: 92,
                                height: 92,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
                                ),
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Entrance(
                              delay: const Duration(milliseconds: 80),
                              child: Column(
                                children: [
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? '',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          delay: const Duration(milliseconds: 140),
                          child: _ProgressCard(percent: percent, summary: summary),
                        ),
                        const SizedBox(height: 12),
                        Entrance(
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Stat(label: 'Pendientes', value: summary.pending, color: Vivid.amber),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Stat(label: 'En curso', value: summary.inProgress, color: Vivid.accent),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _Stat(label: 'Hechas', value: summary.completed, color: Vivid.green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Entrance(
                          delay: const Duration(milliseconds: 260),
                          child: Pressable(
                            onTap: () => _logout(context),
                            semanticLabel: 'Cerrar sesión',
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Vivid.soft(Vivid.red),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, color: Vivid.red, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cerrar sesión',
                                    style: TextStyle(color: Vivid.red, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 14 + media.padding.bottom,
              child: AgendaBottomBar(
                current: AgendaTab.profile,
                onAgenda: () => Navigator.of(context).maybePop(),
                onAdd: () => Navigator.of(context).pushNamed(AppRoutes.taskForm),
                onProfile: () {},
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.percent, required this.summary});

  final int percent;
  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.of(context).disableAnimations;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Vivid.night, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TU PROGRESO',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${summary.completed} de ${summary.total} tareas',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountUp(
                value: percent,
                suffix: ' %',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('completado', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.12)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percent / 100),
                    duration: animate ? const Duration(milliseconds: 1200) : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (_, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(color: Color.lerp(Vivid.accent, Colors.white, 0.3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountUp(
            value: value,
            style: TextStyle(color: color, fontSize: 28, height: 1, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Vivid.muted, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
