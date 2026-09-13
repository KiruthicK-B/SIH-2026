import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted, hot-swappable UI language (README §3 / §8 — a "small flag" in
/// SharedPreferences, independent of the domain data in Hive).
const _localePrefKey = 'agriva_locale';

const supportedAgrivaLocales = [
  Locale('en'),
  Locale('hi'),
  Locale('ta'),
  Locale('te'),
  Locale('pa'),
];

const localeDisplayNames = {
  'en': 'English',
  'hi': 'हिंदी',
  'ta': 'தமிழ்',
  'te': 'తెలుగు',
  'pa': 'ਪੰਜਾਬੀ',
};

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return const Locale('en'); // Defaults cleanly to English; user can change anytime
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale.languageCode);
  }

  bool get hasChosen => state != null;
}

/// Light/dark mode toggle (README §10 — dark mode required), persisted the
/// same way.
const _themeModePrefKey = 'agriva_theme_mode';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModePrefKey);
    state = switch (value) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefKey, mode.name);
  }
}
