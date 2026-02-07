import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Standard Light Theme
  static ThemeData lightTheme({
    double textScale = 1.0,
    bool boldText = false,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20 * textScale,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(textScale, boldText, AppColors.textPrimary),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48), // WCAG min touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16 * textScale,
            fontWeight: boldText ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// High Contrast Theme (WCAG AAA)
  static ThemeData highContrastTheme({
    double textScale = 1.0,
    bool boldText = true,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.highContrastPrimary,
        secondary: Colors.yellow,
        surface: AppColors.highContrastSurface,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.highContrastBackground,
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.highContrastSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22 * textScale,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Text Theme
      textTheme: _buildTextTheme(textScale, true, Colors.white),

      // Button Theme - Larger for accessibility
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highContrastPrimary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          minimumSize: const Size(0, 56), // Larger touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          textStyle: TextStyle(
            fontSize: 18 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        color: AppColors.highContrastSurface,
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.highContrastSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.highContrastPrimary, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: 16 * textScale,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(double scale, bool bold, Color color) {
    final weight = bold ? FontWeight.bold : FontWeight.normal;
    final mediumWeight = bold ? FontWeight.bold : FontWeight.w500;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * scale, fontWeight: weight, color: color),
      displayMedium: TextStyle(fontSize: 45 * scale, fontWeight: weight, color: color),
      displaySmall: TextStyle(fontSize: 36 * scale, fontWeight: weight, color: color),
      headlineLarge: TextStyle(fontSize: 32 * scale, fontWeight: weight, color: color),
      headlineMedium: TextStyle(fontSize: 28 * scale, fontWeight: weight, color: color),
      headlineSmall: TextStyle(fontSize: 24 * scale, fontWeight: mediumWeight, color: color),
      titleLarge: TextStyle(fontSize: 22 * scale, fontWeight: mediumWeight, color: color),
      titleMedium: TextStyle(fontSize: 16 * scale, fontWeight: mediumWeight, color: color),
      titleSmall: TextStyle(fontSize: 14 * scale, fontWeight: mediumWeight, color: color),
      bodyLarge: TextStyle(fontSize: 16 * scale, fontWeight: weight, color: color),
      bodyMedium: TextStyle(fontSize: 14 * scale, fontWeight: weight, color: color),
      bodySmall: TextStyle(fontSize: 12 * scale, fontWeight: weight, color: color),
      labelLarge: TextStyle(fontSize: 14 * scale, fontWeight: mediumWeight, color: color),
      labelMedium: TextStyle(fontSize: 12 * scale, fontWeight: mediumWeight, color: color),
      labelSmall: TextStyle(fontSize: 11 * scale, fontWeight: mediumWeight, color: color),
    );
  }
}
