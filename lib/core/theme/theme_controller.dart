import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Claro/Escuro/Sistema choice (Settings screen) and
/// exposes it as a [ValueListenable] so `MaterialApp.themeMode` rebuilds
/// when it changes. A single instance lives for the app's lifetime —
/// simple app-wide access without threading it through every constructor.
class ThemeController {
  ThemeController._(this.mode);

  static const _prefsKey = 'mimo_theme_mode';

  final ValueNotifier<ThemeMode> mode;

  static late final ThemeController instance;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final resolved = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    instance = ThemeController._(ValueNotifier(resolved));
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newMode.name);
  }
}
