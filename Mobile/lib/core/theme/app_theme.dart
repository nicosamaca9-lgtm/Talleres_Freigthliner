import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // CSS Variables exact match
  static const Color bg = Color(0xFF0B1121); // Azul oscuro casi gris (premium)
  static const Color surface = Color(0xFF131A2A); // Ligeramente más claro para tarjetas
  static const Color surface2 = Color(0xFF1E293B); // Para inputs
  static const Color surface3 = Color(0xFF222222);
  
  static const Color green = Color(0xFF22c55e);
  static const Color greenDim = Color(0xFF16a34a);
  static const Color greenBg = Color(0x1422c55e); // rgba(34,197,94,0.08)
  static const Color borderGreen = Color(0x4D22c55e); // rgba(34,197,94,0.3)
  
  static const Color text = Color(0xFFf5f5f5);
  static const Color textMuted = Color(0xFF888888);
  static const Color textDim = Color(0xFF555555);
  static const Color border = Color(0x11FFFFFF); // rgba(255,255,255,0.07)
  
  static const Color amber = Color(0xFFf59e0b);
  static const Color red = Color(0xFFef4444);
  static const Color blue = Color(0xFF3b82f6);

  static const Color primaryColor = green;
  static const Color surfaceColor = surface;
  static const Color errorColor = red;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: green,
      colorScheme: const ColorScheme.dark(
        primary: green,
        surface: surface,
        error: red,
      ),
      // Set DM Sans as the default body font
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme
      ).copyWith(
        bodyMedium: GoogleFonts.dmSans(color: text),
        bodySmall: GoogleFonts.dmSans(color: textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(color: textDim, fontSize: 13),
        labelStyle: GoogleFonts.dmSans(color: textMuted, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: green, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 1),
        ),
      ),
    );
  }

  // Use this for headings (Rajdhani)
  static TextStyle get headingStyle {
    return GoogleFonts.rajdhani(
      color: text,
      fontWeight: FontWeight.bold,
    );
  }
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      primaryColor: green,
      colorScheme: const ColorScheme.light(
        primary: green,
        surface: Colors.white,
        error: red,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData(brightness: Brightness.light).textTheme
      ).copyWith(
        bodyMedium: GoogleFonts.dmSans(color: const Color(0xFF1F2937)),
        bodySmall: GoogleFonts.dmSans(color: const Color(0xFF4B5563)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(color: const Color(0xFF9CA3AF), fontSize: 13),
        labelStyle: GoogleFonts.dmSans(color: const Color(0xFF6B7280), fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: green, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 1),
        ),
      ),
    );
  }
}
