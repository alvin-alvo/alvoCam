import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlvoTheme {
  // Retro-Futuristic Palette
  static const Color black = Color(0xFF050505);
  static const Color amber = Color(0xFFFFB000);
  static const Color green = Color(0xFF39FF14);
  
  // The "Terminal" Font
  static TextStyle get mono {
    return GoogleFonts.orbitron(
      color: green,
      fontSize: 14,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w500,
    );
  }

  // Global App Theme
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: black,
      primaryColor: amber,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        surface: black,
      ),
    );
  }
}