// ============================================================
// WarmiBot — Tema visual amazónico
// Paleta inspirada en la selva ecuatoriana y el diseño adjunto
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Paleta principal — selva amazónica ─────────────────────
  static const Color primaryGreen     = Color(0xFF1B8A3C);  // Verde selva
  static const Color primaryGreenDark = Color(0xFF0D5C27);  // Verde oscuro
  static const Color accentGreen      = Color(0xFF2ECC71);  // Verde brillante
  static const Color neonGreen        = Color(0xFF00FF88);  // Neón accent (mic)

  // ── Fondos oscuros (tema dark del diseño) ──────────────────
  static const Color bgDark           = Color(0xFF0A1628);  // Azul noche
  static const Color bgCard           = Color(0xFF112040);  // Azul profundo
  static const Color bgSurface        = Color(0xFF1A2F4A);  // Azul medio

  // ── Texto ────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFFFFFFF);
  static const Color textSecondary    = Color(0xFFB0C4DE);
  static const Color textMuted        = Color(0xFF7A9BBE);

  // ── Accents ────────────────────────────────────────────────
  static const Color accentTeal       = Color(0xFF00CED1);
  static const Color accentAmber      = Color(0xFFFFD700);
  static const Color accentCoral      = Color(0xFFFF6B6B);

  // ── Chat bubbles ───────────────────────────────────────────
  static const Color userBubble       = Color(0xFF1B8A3C);
  static const Color botBubble        = Color(0xFF1A2F4A);

  // ── Gradiente principal del avatar ─────────────────────────
  static const List<Color> avatarGradient = [
    Color(0xFF0D5C27),
    Color(0xFF1B8A3C),
    Color(0xFF2ECC71),
  ];

  // ── Gradiente fondo de pantalla ────────────────────────────
  static const List<Color> bgGradient = [
    Color(0xFF050E1C),
    Color(0xFF0A1628),
    Color(0xFF0D2240),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primaryGreen,
        secondary: AppColors.accentGreen,
        surface:   AppColors.bgCard,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14, color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.lato(
          fontSize: 11, color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0x441B8A3C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0x441B8A3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: const Color(0x221B8A3C),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }
}
