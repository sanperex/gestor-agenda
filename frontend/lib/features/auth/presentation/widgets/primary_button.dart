import 'package:flutter/material.dart';

/// Boton principal. Mientras [isLoading] es true muestra un circulo de carga
/// y se desactiva, para que el usuario no envie el formulario dos veces.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.text, required this.onPressed, this.isLoading = false});

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
          : Text(text),
    );
  }
}
