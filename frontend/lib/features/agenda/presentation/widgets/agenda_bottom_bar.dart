import 'package:flutter/material.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';

enum AgendaTab { agenda, profile }

/// Barra inferior flotante: Agenda a la izquierda, crear tarea al centro y Perfil a la derecha.
///
/// Tres espacios iguales dentro de la misma barra: nada sobresale ni se monta sobre el
/// contenido, y el botón de crear queda justo en el centro, al alcance del pulgar.
/// La pestaña activa se marca con una pastilla suave del color de la marca.
class AgendaBottomBar extends StatelessWidget {
  const AgendaBottomBar({
    super.key,
    required this.current,
    required this.onAgenda,
    required this.onAdd,
    required this.onProfile,
  });

  final AgendaTab current;
  final VoidCallback onAgenda;
  final VoidCallback onAdd;
  final VoidCallback onProfile;

  static const double height = 68;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Vivid.line.withValues(alpha: 0.6)),
        boxShadow: Vivid.shadow(strength: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Agenda',
              tooltip: 'Agenda',
              active: current == AgendaTab.agenda,
              onTap: onAgenda,
            ),
          ),
          Expanded(
            child: Center(
              child: Tooltip(
                message: 'Nueva tarea',
                child: Pressable(
                  onTap: onAdd,
                  semanticLabel: 'Nueva tarea',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Vivid.accent, borderRadius: BorderRadius.circular(17)),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              tooltip: 'Mi perfil',
              active: current == AgendaTab.profile,
              onTap: onProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Vivid.accent : Vivid.muted;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticLabel: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Vivid.soft(Vivid.accent, 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
