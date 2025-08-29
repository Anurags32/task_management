import 'package:flutter/material.dart';

class AppTheme {
  static const Color blobGreen = Color(0xFF7EE6B6);
  static const Color blobYellow = Color(0xFFFFECA8);
  static const Color blobBlue = Color(0xFFA8D8FF);
  static const Color blobPurple = Color(0xFFC7B2FF);
  // Main Colors
  static const Color primary = Color(0xFF6C4CE2);
  static const Color primaryDark = Color(0xFF4C33B8);
  static const Color accent = Color(0xFF00C2FF);
  static const Color success = Color(0xFF39C17F);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFE74C3C);
  static const Color softBackground = Color(0xFFF7F7FB);

  // 🌈 Gradient Colors for Landing Page & Backgrounds
  static const Color gradientStart = Color(0xFFB5E0B0); // light green
  static const Color gradientMiddle = Color(0xFFEDEDED); // soft gray/white
  static const Color gradientEnd = Color(0xFFBCAAF5); // light purple

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return base.copyWith(
      colorScheme: colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: softBackground,
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: Colors.black87),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: Colors.black87),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFFE6E6F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}

class StatusColors {
  static const Map<String, Color> map = <String, Color>{
    'done': AppTheme.success,
    'in_progress': AppTheme.warning,
    'pending': AppTheme.primary,
    'blocked': AppTheme.danger,
  };
}
