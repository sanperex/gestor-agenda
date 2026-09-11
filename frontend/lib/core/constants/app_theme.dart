import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema visual comun para todas las pantallas (A y B).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final radius = BorderRadius.circular(12);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, error: AppColors.error),
      scaffoldBackgroundColor: AppColors.background,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: radius),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
