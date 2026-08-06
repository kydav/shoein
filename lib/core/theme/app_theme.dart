import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand palette (constant across light & dark) ────────────────────────────
const kForge = Color(0xFFB45309); // amber-brown primary (hot iron / leather)
const kForgeDark = Color(0xFF8A3D0A);
const kAnvil = Color(0xFF2B2A28); // charcoal — dark surfaces (nav pill, login)
const kAnvilSoft = Color(0xFF3C3A37);
const kSuccessGreen = Color(0xFF4B7B4B);
const kOverdueRed = Color(0xFFB4413A);

// Light-mode neutral tokens (kept as top-level consts for the theme + a few
// brand spots). Prefer `context.colors.*` in widgets so they flip in dark mode.
const kBgPage = Color(0xFFF7F4EF); // warm off-white
const kTextPrimary = Color(0xFF2A2420);
const kTextSecondary = Color(0xFF807668);
const kBorderColor = Color(0xFFE7E1D8);

// ─── Theme-aware neutral colors ──────────────────────────────────────────────
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color pageBg;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const AppColors({
    required this.pageBg,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  static const light = AppColors(
    pageBg: kBgPage,
    surface: Colors.white,
    surfaceAlt: Color(0xFFF0EBE2),
    textPrimary: kTextPrimary,
    textSecondary: kTextSecondary,
    border: kBorderColor,
  );

  static const dark = AppColors(
    pageBg: Color(0xFF1A1613),
    surface: Color(0xFF241E17),
    surfaceAlt: Color(0xFF2E271E),
    textPrimary: Color(0xFFF3EDE4),
    textSecondary: Color(0xFFB4A691),
    border: Color(0xFF3A322A),
  );

  @override
  AppColors copyWith({
    Color? pageBg,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) => AppColors(
    pageBg: pageBg ?? this.pageBg,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// ─── Themes ──────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light =>
      _build(brightness: Brightness.light, c: AppColors.light);

  static ThemeData get dark =>
      _build(brightness: Brightness.dark, c: AppColors.dark);

  static TextTheme _text(TextTheme base, AppColors c) {
    final heading = GoogleFonts.robotoSlabTextTheme(base);
    final body = GoogleFonts.interTextTheme(base);
    return base.copyWith(
      headlineLarge: heading.headlineLarge?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineMedium: heading.headlineMedium?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      headlineSmall: heading.headlineSmall?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleLarge: heading.titleLarge?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: c.textPrimary, fontSize: 15),
      bodyMedium: body.bodyMedium?.copyWith(color: c.textPrimary, fontSize: 14),
      bodySmall: body.bodySmall?.copyWith(color: c.textSecondary, fontSize: 12),
      labelLarge: body.labelLarge?.copyWith(
        color: c.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: c.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: c.textSecondary,
        fontSize: 11,
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required AppColors c,
  }) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      extensions: [c],
      colorScheme: ColorScheme.fromSeed(
        seedColor: kForge,
        brightness: brightness,
        primary: kForge,
        surface: c.surface,
        onSurface: c.textPrimary,
      ),
      scaffoldBackgroundColor: c.pageBg,
      textTheme: _text(base.textTheme, c),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
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
          foregroundColor: c.textPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: c.border),
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
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kForge, width: 2),
        ),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.pageBg,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.robotoSlab(
          color: c.textPrimary,
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
