import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
    }
  }

  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    try {
      _isDarkMode = isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', _isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error setting theme: $e');
    }
  }
}
