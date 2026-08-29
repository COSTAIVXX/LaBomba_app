import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0716);
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accent = Color(0xFFF59E0B);
  static const Color pink = Color(0xFFEC4899);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ).copyWith(secondary: accent),
      scaffoldBackgroundColor: background,
      textTheme: ThemeData.dark().textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withValues(alpha: 0.35)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF211A31),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: primaryLight,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Color(0x665EA5FA)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const bg = Color(0xFFF8F9FA); // soft off-white
    const textPrimary = Color(0xFF1A1A1A);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(secondary: accent),
      scaffoldBackgroundColor: bg,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: textPrimary,
            displayColor: textPrimary,
          ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: textPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(color: textPrimary),
        actionTextColor: primary,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }

}
