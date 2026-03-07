import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1565C0); // deep blue for staff
  static const Color background = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF1A2D42);
  static const Color cardSurface = Color(0x26FFFFFF);
  static const Color cardBorder = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          surface: surface,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textSecondary),
        ),
      );
}
