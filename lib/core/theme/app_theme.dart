import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium frosted-glass light theme inspired by the Dribbble voice AI design.
abstract final class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color bgBase = Color(0xFFF4F5FA);
  static const Color bgSurface = Color(0xFFFFFFFF);
  static const Color orbIdle = Color(0xFFB39DDB); // lavender
  static const Color orbListen = Color(0xFFEF9A9A); // coral
  static const Color orbThink = Color(0xFF90CAF9); // sky blue
  static const Color orbDone = Color(0xFFA5D6A7); // mint

  static const Color accentGradientA = Color(0xFFF7971E); // warm orange
  static const Color accentGradientB = Color(0xFF9B59B6); // violet
  static const Color accentGradientC = Color(0xFF4FC3F7); // light blue

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9B59B6),
        brightness: Brightness.light,
        surface: bgBase,
      ),
      scaffoldBackgroundColor: bgBase,
      dividerColor: divider,
    );

    final dmSans = GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: textSecondary,
      ),
    );

    return base.copyWith(
      textTheme: dmSans,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
    );
  }
}
