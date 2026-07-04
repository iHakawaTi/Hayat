import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Palette
  static const primaryRed = Color(0xFFE11D48); // Vivid Rose
  static const darkRed = Color(0xFF881337); // Deep Rose/Burgundy
  static const blackBackground = Color(0xFF0F0F0F); // Almost Black
  static const surfaceDark = Color(0xFF1E1E1E); // Dark Grey Surface
  
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final TextTheme _textTheme = GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
    displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5),
    bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5),
  );

  // Modern Dark Theme by default (Users wanted premium)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: blackBackground,
    
    colorScheme: ColorScheme.dark(
      primary: primaryRed,
      secondary: const Color(0xFF10B981), // Emerald
      surface: surfaceDark,
      error: const Color(0xFFEF4444),
      onSurface: Colors.white,
    ),

    textTheme: _textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryRed),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      prefixIconColor: Colors.white.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryRed.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
  
  // We keep light theme but make it cleaner too, though we prioritize dark
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    colorScheme: ColorScheme.light(
      primary: primaryRed,
      secondary: const Color(0xFF10B981),
      surface: Colors.white,
    ),
    textTheme: _textTheme.apply(bodyColor: const Color(0xFF0F172A), displayColor: const Color(0xFF0F172A)),
     inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
     elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
