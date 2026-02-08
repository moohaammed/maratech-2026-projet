import 'package:flutter/material.dart';

class AppColors {
  // Primary running theme (Softer Sports Red)
  static const Color primary = Color(0xFFE53935); // Red 600 - More comfortable/Vibrant
  static const Color primaryDark = Color(0xFFC62828); // Red 800
  static const Color primaryLight = Color(0xFFFFEBEE); // Red 50 - Very soft background

  // Secondary (Action/Accent)
  static const Color accent = Color(0xFF2979FF);
  static const Color secondary = accent; // Alias for consistency
  
  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);
  
  // High Contrast (Accessibility) - Friendly & Welcoming
  static const Color highContrastPrimary = Color(0xFF00E5CC); // Soft Teal - Friendly & Accessible
  static const Color highContrastSecondary = Color(0xFF64B5F6); // Soft Blue
  static const Color highContrastSurface = Color(0xFF1E1E2E); // Soft dark (not pure black)
  static const Color highContrastBackground = Color(0xFF0D0D14); // Very soft dark
  
  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);

  // Group Level Colors
  static const Color beginner = Color(0xFF81C784);    // Green
  static const Color intermediate = Color(0xFF64B5F6); // Blue
  static const Color advanced = Color(0xFFE57373);     // Red
  static const Color elite = Color(0xFFBA68C8);        // Purple
}
