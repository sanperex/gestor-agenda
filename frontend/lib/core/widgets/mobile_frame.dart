import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Muestra la app con ancho de celular aunque se abra desde la web en una pantalla ancha.
///
/// La app está diseñada para celular. Estirada a 1400 px en un monitor, la barra
/// inferior, las tarjetas y el formulario quedan desproporcionados. En pantallas anchas
/// se centra en un marco del tamaño de un teléfono; en un celular real (ancho menor al
/// punto de corte) no hace nada.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  static const double phoneWidth = 420;
  static const double _breakpoint = 600;
  static const double _maxHeight = 900;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= _breakpoint) return child;

    // Con alto de sobra se deja un margen y esquinas redondeadas, para que se lea como
    // un teléfono; si la ventana es baja, el marco usa todo el alto.
    final roomy = media.size.height >= 760;
    final margin = roomy ? 24.0 : 0.0;
    final height = math.min(media.size.height - margin * 2, _maxHeight);
    final radius = roomy ? 32.0 : 0.0;

    return ColoredBox(
      color: const Color(0xFFDCDFEA),
      child: Center(
        child: Container(
          width: phoneWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [BoxShadow(color: Color(0x261E1B4B), blurRadius: 40, offset: Offset(0, 16))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            // Las pantallas leen el tamaño de MediaQuery (hojas inferiores, diálogos): se les
            // da el del marco, no el de la ventana entera.
            child: MediaQuery(
              data: media.copyWith(
                size: Size(phoneWidth, height),
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
