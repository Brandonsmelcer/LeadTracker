import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF16213E);
  static const Color accent = Color(0xFFE94560);
  static const Color gold = Color(0xFFD4AF37);
  static const Color surface = Color(0xFF0F3460);
  static const Color background = Color(0xFF0A0A1A);
  static const Color cardDark = Color(0xFF1A1A2E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color success = Color(0xFF00CEC8);
  static const Color warning = Color(0xFFFFA726);
  static const Color accentTeal = Color(0xFF00CEC8);
  static const Color countyFill = Color(0xFF1E3A5F);
  static const Color countyBorder = Color(0xFF3D5A80);
  static const Color countyHighlight = Color(0xFF2E5A88);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.gold,
        surface: AppColors.surface,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent.withAlpha(60),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.countyBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.countyBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      dividerColor: AppColors.countyBorder,
    );
  }
}
