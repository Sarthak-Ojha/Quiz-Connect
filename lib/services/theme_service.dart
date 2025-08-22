import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode get themeMode => ThemeMode.light;

  Future<void> initialize() async {
    try {
      // Theme service initialized for light mode only
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing theme: $e');
    }
  }
}
