import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette (warm forge / leather) ──────────────────────────────────────────
const kForge = Color(0xFFB45309); // amber-brown primary (hot iron / leather)
const kForgeDark = Color(0xFF8A3D0A);
const kAnvil = Color(0xFF2B2A28); // charcoal — dark surfaces
const kAnvilSoft = Color(0xFF3C3A37);
const kBgPage = Color(0xFFF7F4EF); // warm off-white
const kTextPrimary = Color(0xFF2A2420);
const kTextSecondary = Color(0xFF807668);
const kBorderColor = Color(0xFFE7E1D8);
const kSuccessGreen = Color(0xFF4B7B4B);
const kOverdueRed = Color(0xFFB4413A);

class AppTheme {
  static TextTheme _text(TextTheme base) {
    final heading = GoogleFonts.robotoSlabTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);
    return base.copyWith(
      headlineLarge: heading.headlineLarge?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineMedium: heading.headlineMedium?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      headlineSmall: heading.headlineSmall?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleLarge: heading.titleLarge?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: kTextPrimary, fontSize: 15),
      bodyMedium: body.bodyMedium?.copyWith(color: kTextPrimary, fontSize: 14),
      bodySmall: body.bodySmall?.copyWith(color: kTextSecondary, fontSize: 12),
      labelLarge: body.labelLarge?.copyWith(
        color: kTextPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: kTextSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: kTextSecondary,
        fontSize: 11,
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kForge,
        primary: kForge,
        surface: Colors.white,
        onSurface: kTextPrimary,
      ),
      scaffoldBackgroundColor: kBgPage,
      textTheme: _text(base.textTheme),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: kBorderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kForge,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kAnvil,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: kBorderColor),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kForge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kForge, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(color: kBorderColor, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: kBgPage,
        foregroundColor: kTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.robotoSlab(
          color: kTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kForge,
        foregroundColor: Colors.white,
      ),
    );
  }
}
