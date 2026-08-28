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
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.light,
      ).copyWith(secondary: accent),
      scaffoldBackgroundColor: Colors.white,
      textTheme: ThemeData.light().textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFFF1F5FF),
        contentTextStyle: TextStyle(color: Color(0xFF172554)),
        actionTextColor: primary,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: Color(0x662563EB)),
        ),
      ),
    );
  }

}
