import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Muestra un mensaje abajo en la pantalla (verde = exito, rojo = error).
///
/// Recibe el [ScaffoldMessengerState] y no el context, porque despues de un login
/// la pantalla puede cerrarse antes de mostrar el mensaje.
void showMessage(ScaffoldMessengerState messenger, String message, {bool isError = false}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
}
