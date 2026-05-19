import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Global Theme Mode State
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // Dynamic getters for colors depending on theme state
  static Color get background => themeNotifier.value == ThemeMode.light 
      ? const Color(0xFFF8FAFC) // Slate 50
      : const Color(0xFF0F172A); // Slate 900

  static Color get surface => themeNotifier.value == ThemeMode.light 
      ? const Color(0xFFFFFFFF) // White
      : const Color(0xFF1E293B); // Slate 800

  static Color get textPrimary => themeNotifier.value == ThemeMode.light 
      ? const Color(0xFF0F172A) // Slate 900
      : const Color(0xFFF8FAFC); // Slate 50

  static Color get textSecondary => themeNotifier.value == ThemeMode.light 
      ? const Color(0xFF64748B) // Slate 500
      : const Color(0xFF94A3B8); // Slate 400

  // Brand Colors (remain same in both themes)
  static const Color primary = Color(0xFF8B5CF6); // Violet 500
  static const Color secondary = Color(0xFFEC4899); // Pink 500
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Dark Theme Definition
  static ThemeData get darkTheme {
    const darkBg = Color(0xFF0F172A);
    const darkSurface = Color(0xFF1E293B);
    const darkTextPrimary = Color(0xFFF8FAFC);
    const darkTextSecondary = Color(0xFF94A3B8);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
        background: darkBg,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.outfit(color: darkTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: darkTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    const lightBg = Color(0xFFF8FAFC);
    const lightSurf = Color(0xFFFFFFFF);
    const lightTextPrim = Color(0xFF0F172A);
    const lightTextSec = Color(0xFF64748B);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: lightSurf,
        background: lightBg,
        error: error,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: lightTextPrim, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: lightTextPrim, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.outfit(color: lightTextPrim),
        bodyMedium: GoogleFonts.outfit(color: lightTextSec),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrim),
        titleTextStyle: TextStyle(color: lightTextPrim, fontSize: 20, fontWeight: FontWeight.bold),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurf,
        selectedItemColor: primary,
        unselectedItemColor: lightTextSec,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: lightSurf,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurf,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: lightTextSec),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
