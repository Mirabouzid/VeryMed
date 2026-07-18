import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thème global Material 3 - El Asli
/// Palette santé : vert émeraude + bleu médical
class AppTheme {
  AppTheme._();

  // ── Couleurs ────────────────────────────────────────────────────
  static const Color primaryGreen    = Color(0xFF00C896);
  static const Color primaryGreenDark= Color(0xFF00A87A);
  static const Color accentBlue      = Color(0xFF2196F3);
  static const Color accentBlueDark  = Color(0xFF1565C0);
  static const Color dangerRed       = Color(0xFFE53935);
  static const Color dangerRedLight  = Color(0xFFFFEBEE);
  static const Color warningOrange   = Color(0xFFFF9800);
  static const Color successGreen    = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFFE8F5E9);

  // Light
  static const Color surfaceLight    = Color(0xFFF8FFFE);
  static const Color cardLight       = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF0FAF7);

  // Dark
  static const Color surfaceDark     = Color(0xFF0D1B18);
  static const Color cardDark        = Color(0xFF162420);
  static const Color backgroundDark  = Color(0xFF0A1612);

  // Text
  static const Color textPrimaryLight   = Color(0xFF1A2F2B);
  static const Color textSecondaryLight = Color(0xFF4A6560);
  static const Color textPrimaryDark    = Color(0xFFE8F5F2);
  static const Color textSecondaryDark  = Color(0xFF8FBFB8);

  // ── Light Theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: accentBlue,
      error: dangerRed,
      surface: surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: backgroundLight,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimaryLight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE7E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE7E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF9EBEBB),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── TextTheme sans fontFamily ni backgroundColor ─────────────
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimaryLight),
        displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimaryLight),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryLight),
        headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryLight),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryLight),
        titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimaryLight),
        bodyLarge:     TextStyle(fontSize: 15, color: textPrimaryLight),
        bodyMedium:    TextStyle(fontSize: 14, color: textSecondaryLight),
        bodySmall:     TextStyle(fontSize: 12, color: textSecondaryLight),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall:    TextStyle(fontSize: 11),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final cs = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: primaryGreen,
      secondary: accentBlue,
      error: dangerRed,
      surface: surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: backgroundDark,

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF4A6560),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimaryDark),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryDark),
        headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryDark),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryDark),
        titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimaryDark),
        bodyLarge:     TextStyle(fontSize: 15, color: textPrimaryDark),
        bodyMedium:    TextStyle(fontSize: 14, color: textSecondaryDark),
        bodySmall:     TextStyle(fontSize: 12, color: textSecondaryDark),
        labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
