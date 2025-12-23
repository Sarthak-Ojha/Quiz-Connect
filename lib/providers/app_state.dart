import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' show FlutterSecureStorage, AndroidOptions;

class AppState with ChangeNotifier {
  // Singleton instance
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  // Secure storage
  late final FlutterSecureStorage _secureStorage;

  // State variables with default values
  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _isFirstLaunch = true;
  final bool _isOnline = true;
  String? _currentUserId;
  String? _authToken;
  String? _languageCode;
  double _textScaleFactor = 1.0;
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _isInitialized = false;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isOnline => _isOnline;
  String? get currentUserId => _currentUserId;
  String? get authToken => _authToken;
  String? get languageCode => _languageCode;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  bool get reducedMotion => _reducedMotion;
  bool get isInitialized => _isInitialized;


  // Initialize the app state
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Load preferences
      await _loadPreferences();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AppState: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _highContrast = prefs.getBool('highContrast') ?? false;
    _reducedMotion = prefs.getBool('reducedMotion') ?? false;
    _languageCode = prefs.getString('languageCode') ?? 'en';
    
    // Load sensitive data from secure storage
    _authToken = await _getSecureData('authToken');
    _currentUserId = await _getSecureData('currentUserId');
    
    // Update first launch status
    if (_isFirstLaunch) {
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  
  Future<void> _saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> _getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  Future<void> _deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Theme methods
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

  // Reduced motion
  Future<void> toggleReducedMotion() async {
    _reducedMotion = !_reducedMotion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reducedMotion', _reducedMotion);
    notifyListeners();
  }

  // Language
  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  // Authentication
  Future<void> setAuthState({required String userId, required String token}) async {
    _currentUserId = userId;
    _authToken = token;
    
    await Future.wait([
      _saveSecureData('currentUserId', userId),
      _saveSecureData('authToken', token),
    ]);
    
    notifyListeners();
  }

  Future<void> clearAuthState() async {
    _currentUserId = null;
    _authToken = null;
    
    await Future.wait([
      _deleteSecureData('currentUserId'),
      _deleteSecureData('authToken'),
    ]);
    
    notifyListeners();
  }

  // Loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear all state (for logout)
  Future<void> clearAll() async {
    _isLoading = false;
    _currentUserId = null;
    _authToken = null;
    
    try {
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      // Reset preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing app state: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
}

// Helper class for dependency injection
class AppStateProvider extends StatelessWidget {
  final Widget child;
  final AppState appState;

  AppStateProvider({
    super.key,
    required this.child,
    AppState? appState,
  }) : appState = appState ?? AppState._internal();

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedAppState>()!.appState;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedAppState(
      appState: appState,
      child: child,
    );
  }
}

class _InheritedAppState extends InheritedWidget {
  final AppState appState;

  const _InheritedAppState({
    required this.appState,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAppState oldWidget) => true;
}
