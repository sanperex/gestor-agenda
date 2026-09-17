import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/vivid.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/vivid_backdrop.dart';

/// Marco comun de las pantallas de auth: icono, titulo, subtitulo y una tarjeta con el formulario.
/// El ancho maximo evita que en la web el formulario ocupe toda la pantalla.
///
/// Rediseño (Aprendiz B): fondo índigo sólido y la tarjeta blanca encima. Solo cambia el marco; los formularios de cada pantalla, sus textos y
/// su logica siguen siendo los mismos.
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
    final theme = Theme.of(context);

    // Dentro de la tarjeta los campos van rellenos de lavanda y sin contorno, y se
    // marcan en índigo al enfocarlos. Se aplica con un Theme local para no tocar los
    // campos de cada pantalla.
    final radius = BorderRadius.circular(16);
    final cardTheme = theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Vivid.field,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Vivid.accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFDC2626))),
        focusedErrorBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Vivid.accent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Vivid.accent,
        appBar: showBackButton
            ? AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0)
            : null,
        body: Stack(
          children: [
            const Positioned.fill(child: VividBackdrop()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Entrance(
                            offsetY: 0,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: Vivid.glass(radius: 26),
                              child: Icon(icon, size: 36, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Entrance(
                          delay: const Duration(milliseconds: 100),
                          child: Column(
                            children: [
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  height: 1.05,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Entrance(
                          delay: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: Vivid.shadow(strength: 2),
                            ),
                            child: Theme(data: cardTheme, child: child),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
