import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Primary warm brand colors (inspired by Paisa & modern fintech)
  static const primaryWarm = Color(0xFFF48C6A); // Warm terracotta peach
  static const mintAccent = Color(0xFF00D09C); // Fresh emerald mint
  static const bgDarkWarm = Color(0xFF131110); // Rich warm espresso obsidian
  static const cardDarkWarm = Color(0xFF1E1A18); // Elevated warm dark card
  static const borderDarkWarm = Color(0xFF2C2623); // Subtle card outline

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFE05A47),
      onPrimary: Colors.white,
      secondary: Color(0xFF00D09C),
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1C1917),
      surfaceContainerHighest: Color(0xFFF5F3EF),
      outline: Color(0xFFE7E5E4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFAF8F5),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE7E5E4)),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryWarm,
      onPrimary: Colors.black,
      secondary: mintAccent,
      onSecondary: Colors.black,
      tertiary: Color(0xFF38BDF8),
      onTertiary: Colors.black,
      error: Color(0xFFF87171),
      onError: Colors.black,
      surface: cardDarkWarm,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF25201D),
      outline: borderDarkWarm,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgDarkWarm,
      cardTheme: CardTheme(
        color: cardDarkWarm,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDarkWarm),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
