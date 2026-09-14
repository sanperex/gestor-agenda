import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Piezas de movimiento del rediseño. Solo usan lo que trae Flutter: nada de paquetes.

// `flutter test` define FLUTTER_TEST. Se consulta solo fuera de la web, donde dart:io no
// tiene entorno que leer.
final bool _enPruebas = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

/// Movimiento continuo (fondo que se desplaza, punto que late).
///
/// Se apaga si el sistema pide reducir movimiento, y tambien durante las pruebas: una
/// animacion infinita nunca termina, y `pumpAndSettle` se quedaria esperando a que la
/// pantalla se quede quieta hasta agotar el tiempo. Las animaciones de entrada si corren
/// en pruebas, porque terminan.
bool ambientMotion(BuildContext context) => !_enPruebas && !MediaQuery.of(context).disableAnimations;

bool _entranceMotion(BuildContext context) => !MediaQuery.of(context).disableAnimations;

/// Aparece subiendo y desvaneciéndose, con un retraso para poder escalonar una lista.
///
/// El retraso va dentro de la propia animacion (un [Interval]) y no en un Future.delayed:
/// un temporizador pendiente al cerrar la pantalla hace fallar las pruebas de widgets.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = Duration.zero, this.offsetY = 22});

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 650);

  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + _run;
    _controller = AnimationController(vsync: this, duration: total);
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_entranceMotion(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (_, child) {
        final v = _progress.value;
        return Opacity(
          opacity: v.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offsetY),
            child: Transform.scale(scale: 0.97 + 0.03 * v, child: child),
          ),
        );
      },
    );
  }
}

/// Se hunde un poco al tocarlo: la respuesta que se espera de algo tocable en un celular.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap != null && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Punto que late: señala lo que está pasando ahora.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = Colors.white, this.size = 9});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    if (ambientMotion(context)) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.7 * (1 - t)),
                spreadRadius: 9 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Numero que cuenta desde 0 hasta [value].
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, this.style, this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: _entranceMotion(context) ? const Duration(milliseconds: 1300) : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}
