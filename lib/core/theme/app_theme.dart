import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color bgPrimary = Color(0xFF060A14);
  static const Color bgSecondary = Color(0xFF0A0E1A);
  static const Color bgTertiary = Color(0xFF0F1525);
  static const Color glassLight = Color(0x14FFFFFF);
  static const Color glassMedium = Color(0x1FFFFFFF);
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFF33E5C5);
  static const Color accentStrong = Color(0xFF5CF0D8);
  static const Color accentGlow = Color(0x2633E5C5);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color success = Color(0xFF22C55E);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: accent,
        secondary: accentStrong,
        surface: bgSecondary,
        error: danger,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'GoogleSans',
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        fontFamily: 'GoogleSans',
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: glassLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassLight,
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgSecondary.withValues(alpha: 0.92),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bgPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      dividerColor: glassBorder,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
    );
  }
}
