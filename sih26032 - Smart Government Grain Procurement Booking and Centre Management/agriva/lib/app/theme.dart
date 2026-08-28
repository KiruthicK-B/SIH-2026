import 'package:flutter/material.dart';

/// Central color + text style tokens for AGRIVA. Government-service visual
/// language: restrained primary, light neutral background, no gradients.
class AgrivaColors {
  AgrivaColors._();

  static const primary = Color(0xFF1F5D3B);
  static const primaryDark = Color(0xFF14432A);
  static const primaryLight = Color(0xFFE7F2EC);

  /// Operator/manager screens use a distinct blue to signal "official view"
  /// vs the farmer-facing green (matches the approved mockup).
  static const operatorPrimary = Color(0xFF1E4E8C);
  static const operatorPrimaryDark = Color(0xFF12315B);
  static const operatorPrimaryLight = Color(0xFFE7EEF7);

  static const background = Color(0xFFF5F6F7);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E5E4);

  static const textPrimary = Color(0xFF1A1F1C);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFEAF7EF);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFDF3E3);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFCEAEA);
  static const info = Color(0xFF2563EB);
  static const infoBg = Color(0xFFEAF1FD);
  static const inactive = Color(0xFF9CA3AF);
  static const inactiveBg = Color(0xFFF1F2F3);
}

class AgrivaTheme {
  AgrivaTheme._();

  static ThemeData get light => _build(AgrivaColors.primary);

  /// Same visual language, blue primary — used for the operator role shell.
  static ThemeData get operatorBlue => _build(AgrivaColors.operatorPrimary);

  static ThemeData _build(Color primary) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: AgrivaColors.surface,
        error: AgrivaColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AgrivaColors.background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AgrivaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AgrivaColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AgrivaColors.border,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AgrivaColors.inactive,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AgrivaColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AgrivaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AgrivaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AgrivaColors.error),
        ),
        labelStyle: const TextStyle(
          color: AgrivaColors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AgrivaColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AgrivaColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AgrivaColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AgrivaColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AgrivaColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          color: AgrivaColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13.5,
          color: AgrivaColors.textSecondary,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          color: AgrivaColors.textMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AgrivaColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
