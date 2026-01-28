import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Dark Palette
  static const Color darkBackground = Color(0xFF0F1115); // Deep Blue-Grey Black
  static const Color darkSurface = Color(0xFF181B21); // Slightly Lighter
  static const Color darkCard = Color(0xFF1E2329); // Differentiable Card
  static const Color darkBorder = Color(0xFF2F3640); // Subtle Border

  static const Color darkPrimaryText = Color(0xFFF3F4F6); // Soft White
  static const Color darkSecondaryText = Color(0xFF9CA3AF); // Muted Grey
  static const Color darkMuted = Color(0xFF6B7280);

  static const Color brandPrimary = Color(0xFF16A34A);
  static const Color brandSecondary = Color(0xFF008695);

  static const Color errorRed = Color(0xFFEF4444);
  static const Color ambientGlow = Color.fromARGB(255, 206, 253, 246);

  // Global Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF39BB5E), Color(0xFF008695)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: brandPrimary,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: darkSurface,
        onSurface: darkPrimaryText,
        error: errorRed,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground, // Blend with background
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkPrimaryText),
        titleTextStyle: TextStyle(
          color: darkPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),

      // Text Theme
      textTheme: GoogleFonts.cairoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: darkPrimaryText, displayColor: darkPrimaryText),

      // Divider Theme
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandPrimary),
        ),
        labelStyle: const TextStyle(color: darkSecondaryText),
        hintStyle: const TextStyle(color: darkMuted),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: darkPrimaryText),
    );
  }
}
