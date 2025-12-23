import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  bool _isDarkMode = false;
  double _textScaleFactor = 1.0;
  bool _highContrast = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isDarkMode => _isDarkMode;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;

  // Initialize from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _highContrast = prefs.getBool('highContrast') ?? false;
    notifyListeners();
  }

  // Loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Error handling
  void setError(String? error) {
    _error = error;
    if (error != null) {
      _successMessage = null;
    }
    notifyListeners();
  }

  // Success messages
  void setSuccess(String? message) {
    _successMessage = message;
    if (message != null) {
      _error = null;
    }
    notifyListeners();
  }

  // Theme management
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Text scaling
  Future<void> updateTextScaleFactor(double factor) async {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', _textScaleFactor);
    notifyListeners();
  }

  // High contrast mode
  Future<void> toggleHighContrast() async {
    _highContrast = !_highContrast;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', _highContrast);
    notifyListeners();
  }

  // Clear all state
  void clear() {
    _isLoading = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}

// Usage:
// final appState = Provider.of<AppState>(context, listen: false);
// appState.setLoading(true);
// try {
//   // Your code here
//   appState.setSuccess('Operation completed successfully');
// } catch (e) {
//   appState.setError('An error occurred: $e');
// } finally {
//   appState.setLoading(false);
// }
