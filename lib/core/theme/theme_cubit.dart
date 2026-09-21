import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, dark, light }

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themePrefKey = 'selected_theme_mode';

  ThemeCubit() : super(ThemeMode.system) {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          emit(ThemeMode.dark);
        } else if (savedTheme == 'light') {
          emit(ThemeMode.light);
        } else {
          emit(ThemeMode.system);
        }
      }
    } catch (_) {
      // Fallback to system theme on error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.dark) {
        await prefs.setString(_themePrefKey, 'dark');
      } else if (mode == ThemeMode.light) {
        await prefs.setString(_themePrefKey, 'light');
      } else {
        await prefs.setString(_themePrefKey, 'system');
      }
    } catch (_) {}
  }
}
