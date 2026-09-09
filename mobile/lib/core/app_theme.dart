import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF12365A);
  static const blue = Color(0xFF1466B8);
  static const teal = Color(0xFF00A8A8);
  static const sky = Color(0xFFE9F4FF);
  static const background = Color(0xFFF5F8FC);
  static const text = Color(0xFF152536);
  static const muted = Color(0xFF617184);
  static const success = Color(0xFF16866A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFD14343);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.teal,
      surface: Colors.white,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD7E1EC)),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1, color: AppColors.text),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.text),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
        bodyLarge: TextStyle(height: 1.45, color: AppColors.text),
        bodyMedium: TextStyle(height: 1.4, color: AppColors.text),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4EBF3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.blue, width: 2)),
        errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
        labelStyle: const TextStyle(color: AppColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: Color(0xFFB9C8D8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.sky,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.blue : AppColors.muted,
            )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

