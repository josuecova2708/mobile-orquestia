import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0A0A0A);
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFEAEAEA);
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const active = Color(0xFF2563EB);
  static const activeLight = Color(0xFFEFF6FF);
  static const completed = Color(0xFF16A34A);
  static const completedLight = Color(0xFFF0FDF4);
  static const cancelled = Color(0xFFDC2626);
  static const cancelledLight = Color(0xFFFEF2F2);
  static const pending = Color(0xFF6B7280);
  static const pendingLight = Color(0xFFF9FAFB);
  static const error = Color(0xFFDC2626);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        titleLarge: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        labelLarge: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
