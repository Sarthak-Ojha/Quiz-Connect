import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      debugPrint(
        '🎨 Theme initialized: ${_isDarkMode ? 'Dark' : 'Light'} mode',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing theme: $e');
    }
  }

  /// Toggle between dark and light mode
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      debugPrint('🎨 Theme toggled to: ${_isDarkMode ? 'Dark' : 'Light'} mode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode == isDark) return;

    try {
      _isDarkMode = isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      debugPrint('🎨 Theme set to: ${_isDarkMode ? 'Dark' : 'Light'} mode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting theme: $e');
    }
  }
}
