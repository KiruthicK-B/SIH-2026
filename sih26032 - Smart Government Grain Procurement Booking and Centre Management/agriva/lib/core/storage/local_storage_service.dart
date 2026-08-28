import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';

/// Persists [AgrivaAppState] as a single JSON blob in shared_preferences.
/// No backend, no database — this is the entire persistence layer.
class LocalStorageService {
  static const _stateKey = 'agriva_state';

  Future<AgrivaAppState?> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_stateKey);
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return AgrivaAppState.fromJson(decoded);
    } catch (_) {
      // Corrupt/unreadable local state — caller falls back to fresh seed data.
      return null;
    }
  }

  Future<void> saveState(AgrivaAppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stateKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stateKey);
  }
}
