import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Paleta del rediseño de la app.
///
/// Parte del índigo que ya usa la app ([AppColors.primary]): cabeceras de color sólido,
/// fondo lavanda suave en vez de blanco y un color propio para cada estado. Estilo
/// plano a propósito: colores sólidos, sombras suaves y sin brillos, para que la
/// pantalla se lea tranquila. Los tonos derivados se calculan desde el índigo, así que
/// cambiar [AppColors.primary] recolorea todo.
class Vivid {
  Vivid._();

  static const Color accent = AppColors.primary;
  static const Color deep = Color(0xFF1E1B4B);
  static const Color night = Color(0xFF1F1D47);
  static const Color lavender = Color(0xFFF1F2F8);
  static const Color field = Color(0xFFF1F2F8);
  static const Color ink = Color(0xFF14162B);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFD4D7E3);

  static const Color red = Color(0xFFDC2626);
  static const Color amber = Color(0xFFD97706);
  static const Color green = AppColors.success;
  static const Color cyan = Color(0xFF0891B2);

  static Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// Índigo un poco más oscuro, para la tarjeta de la tarea en curso: se distingue de la
  /// cabecera sin necesitar degradado.
  static Color get accentDark => _mix(accent, deep, 0.3);

  /// Fondo sólido de un color con poca opacidad: la base de iconos y pastillas.
  static Color soft(Color color, [double alpha = 0.12]) => color.withValues(alpha: alpha);

  /// Sombra suave y neutra. Da un poco de separación sin llamar la atención.
  static List<BoxShadow> shadow({double strength = 1}) => [
    BoxShadow(
      color: deep.withValues(alpha: 0.08 * strength),
      blurRadius: 18,
      offset: const Offset(0, 6),
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> get card => shadow();

  /// Superficie translúcida sobre la cabecera (buscador, filtros, botones).
  static BoxDecoration glass({double radius = 16}) =>
      BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(radius));
}
