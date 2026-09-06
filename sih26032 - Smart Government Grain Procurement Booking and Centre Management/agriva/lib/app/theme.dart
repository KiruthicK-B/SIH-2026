import 'package:flutter/material.dart';

/// Central color + text style tokens for AGRIVA, derived from the brand
/// logo (README §1). One consistent palette across every role — the sample
/// UI reference uses the same green/gold system everywhere, not a
/// role-specific accent.
class AgrivaColors {
  AgrivaColors._();

  static const primary = Color(0xFF155E32); // deep government forest green
  static const primaryDark = Color(0xFF0D3D20);
  static const primaryMedium = Color(0xFF16A34A);
  static const primaryLight = Color(0xFFE8F5E9);
  static const primaryLight50 = Color(0xFFF2F9F3);

  static const gold = Color(0xFFD97706); // secondary / CTA accent
  static const goldDark = Color(0xFF92400E);
  static const goldLight = Color(0xFFFEF3C7);
  static const leaf = Color(0xFF16A34A); // success / accepted accent
  static const emeraldLight = Color(0xFFDCFCE7);

  static const background = Color(0xFFF8FAF8); // crisp clean canvas
  static const surface = Color(0xFFFFFFFF); // pure white cards
  static const border = Color(0xFFE2E8F0); // subtle divider/card border
  static const borderLight = Color(0xFFEDF2EE);

  static const textPrimary = Color(0xFF0F172A); // high contrast slate
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);

  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = Color(0xFF1D4ED8);
  static const infoBg = Color(0xFFDBEAFE);
  static const inactive = Color(0xFF94A3B8);
  static const inactiveBg = Color(0xFFF1F5F9);

  // Dark-mode surfaces (fallback)
  static const backgroundDark = Color(0xFF0D1611);
  static const surfaceDark = Color(0xFF14221A);
  static const surfaceElevatedDark = Color(0xFF1B2E23);
  static const borderDark = Color(0xFF233B2D);
  static const textPrimaryDark = Color(0xFFF3F7F4);
  static const textSecondaryDark = Color(0xFFA5B7AC);
  static const primaryAccentDark = Color(0xFF22C55E);

  static Color surfaceFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surface;

  static Color borderFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : border;

  static Color textPrimaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;

  static Color primaryFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryAccentDark : primary;
}

class AgrivaTheme {
  AgrivaTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AgrivaColors.backgroundDark : AgrivaColors.background;
    final surface = isDark ? AgrivaColors.surfaceDark : AgrivaColors.surface;
    final border = isDark ? AgrivaColors.borderDark : AgrivaColors.border;
    final textPrimary = isDark
        ? AgrivaColors.textPrimaryDark
        : AgrivaColors.textPrimary;
    final textSecondary = isDark
        ? AgrivaColors.textSecondaryDark
        : AgrivaColors.textSecondary;
    final primary = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AgrivaColors.primary,
        primary: primary,
        secondary: AgrivaColors.gold,
        surface: surface,
        error: AgrivaColors.error,
        brightness: brightness,
      ),
      cardColor: surface,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F2618) : AgrivaColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: null,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFD1E7DD),
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 0 : 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF334155) : AgrivaColors.inactive,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AgrivaColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AgrivaColors.textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary,
        unselectedItemColor: isDark ? const Color(0xFF94A3B8) : AgrivaColors.inactive,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: textPrimary, height: 1.4),
        bodyMedium: TextStyle(fontSize: 13.5, color: textSecondary, height: 1.4),
        labelSmall: const TextStyle(fontSize: 11, color: AgrivaColors.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AgrivaColors.primaryDark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Border tint that pairs with each `StatusTone` fill (see
/// `widgets/status_badge.dart`) to match the outlined-chip look in the
/// sample UI reference (chip-green/chip-amber/chip-red strokes).
Color statusToneBorder(String toneName) => switch (toneName) {
  'success' => AgrivaColors.leaf,
  'warning' => AgrivaColors.gold,
  'error' => const Color(0xFFC0463C),
  'info' => AgrivaColors.info,
  _ => AgrivaColors.inactive,
};
