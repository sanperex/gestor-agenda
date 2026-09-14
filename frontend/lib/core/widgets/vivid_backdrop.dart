import 'package:flutter/material.dart';

import '../theme/vivid.dart';
import 'motion.dart';

/// Fondo de las cabeceras y del login: índigo sólido con dos círculos claros muy tenues
/// que se desplazan despacio. Da algo de vida sin recargar la pantalla.
class VividBackdrop extends StatefulWidget {
  const VividBackdrop({super.key});

  @override
  State<VividBackdrop> createState() => _VividBackdropState();
}

class _VividBackdropState extends State<VividBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    if (ambientMotion(context)) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Vivid.accent,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Stack(
              children: [
                _Circle(size: 260, alpha: 0.07, alignment: Alignment(1.3 - 0.15 * t, -1.2 + 0.15 * t)),
                _Circle(size: 200, alpha: 0.05, alignment: Alignment(-1.25 + 0.15 * t, 0.9 - 0.1 * t)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.alpha, required this.alignment});

  final double size;
  final double alpha;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}
