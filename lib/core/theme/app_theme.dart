import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Standard Light Theme
  static ThemeData lightTheme({
    double textScale = 1.0,
    bool boldText = false,
    bool isDyslexic = false,
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
      textTheme: _buildTextTheme(textScale, boldText, isDyslexic, AppColors.textPrimary),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48), // WCAG min touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
    bool isDyslexic = false,
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
      textTheme: _buildTextTheme(textScale, true, isDyslexic, Colors.white),

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

  static TextTheme _buildTextTheme(double scale, bool bold, bool isDyslexic, Color color) {
    final weight = bold ? FontWeight.bold : FontWeight.normal;
    final mediumWeight = bold ? FontWeight.bold : FontWeight.w500;
    
    // Dyslexia adjustments: Extra spacing and line height
    final double letterSpacing = isDyslexic ? 1.5 : 0.0;
    final double wordSpacing = isDyslexic ? 2.0 : 0.0;
    final double height = isDyslexic ? 1.4 : 1.2;

    TextStyle base(double size, FontWeight w) => TextStyle(
      fontSize: size * scale, 
      fontWeight: w, 
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      fontFamily: isDyslexic ? 'Verdana' : null, // Prefer sans-serif for dyslexia
    );

    return TextTheme(
      displayLarge: base(57, weight),
      displayMedium: base(45, weight),
      displaySmall: base(36, weight),
      headlineLarge: base(32, weight),
      headlineMedium: base(28, weight),
      headlineSmall: base(24, mediumWeight),
      titleLarge: base(22, mediumWeight),
      titleMedium: base(16, mediumWeight),
      titleSmall: base(14, mediumWeight),
      bodyLarge: base(16, weight),
      bodyMedium: base(14, weight),
      bodySmall: base(12, weight),
      labelLarge: base(14, mediumWeight),
      labelMedium: base(12, mediumWeight),
      labelSmall: base(11, mediumWeight),
    );
  }
}
