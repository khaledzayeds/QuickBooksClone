// app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme(String languageCode) => _buildTheme(Brightness.light, languageCode);
  static ThemeData darkTheme(String languageCode)  => _buildTheme(Brightness.dark, languageCode);

  static ThemeData _buildTheme(Brightness brightness, String languageCode) {
    final isDark = brightness == Brightness.dark;

    final bg       = isDark ? AppColors.bgDark       : AppColors.bgLight;
    final surface  = isDark ? AppColors.surfaceDark   : AppColors.surfaceLight;
    final text     = isDark ? AppColors.textDark      : AppColors.textLight;
    final muted    = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final border   = isDark ? AppColors.borderDark    : AppColors.borderLight;
    final divider  = isDark ? AppColors.dividerDark   : AppColors.dividerLight;
    final primary  = isDark ? AppColors.primaryDark   : AppColors.primary;

    final baseTextTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = languageCode == 'ar'
        ? GoogleFonts.cairoTextTheme(baseTextTheme)
        : GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      textTheme: textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary,
        onSecondary: Colors.white,
        error: isDark ? AppColors.errorDark : AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),

      scaffoldBackgroundColor: bg,
      dividerColor: divider,

      // ─── AppBar ───────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: text),
      ),

      // ─── Card ─────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Input ────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.error,
          ),
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
      ),

      // ─── Elevated Button ──────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ─── Text Button ──────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ─── Outlined Button ──────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}