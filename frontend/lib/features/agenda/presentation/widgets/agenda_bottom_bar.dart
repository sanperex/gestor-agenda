import 'package:flutter/material.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';

enum AgendaTab { agenda, profile }

/// Barra inferior flotante: Agenda y Perfil a los lados, crear tarea al centro.
///
/// Es el patrón de navegación de un celular: las dos pantallas principales quedan a
/// un toque y la acción más frecuente, crear, en el centro, al alcance del pulgar.
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: Vivid.night,
              borderRadius: BorderRadius.circular(24),
              boxShadow: Vivid.shadow(strength: 2),
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
                const SizedBox(width: 84),
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
          ),
          Positioned(
            top: 0,
            child: Tooltip(
              message: 'Nueva tarea',
              child: Pressable(
                onTap: onAdd,
                semanticLabel: 'Nueva tarea',
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Vivid.accent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Vivid.lavender, width: 5),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
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
    final color = active ? Colors.white : Colors.white.withValues(alpha: 0.5);
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticLabel: tooltip,
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w600),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
