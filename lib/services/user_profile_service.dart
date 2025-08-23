import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  static const String _customNamePrefix = 'custom_display_name_';
  
  // ValueNotifier to notify listeners when display name changes
  static final ValueNotifier<String?> _displayNameNotifier = ValueNotifier<String?>(null);

  /// Get the display name for the current user
  /// Priority: Custom name > Firebase displayName > 'Quiz Master'
  static Future<String> getDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Quiz Master';

    final prefs = await SharedPreferences.getInstance();
    final customName = prefs.getString('$_customNamePrefix${user.uid}');
    
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }
    
    return user.displayName ?? 'Quiz Master';
  }

  /// Save a custom display name for the current user
  static Future<void> saveCustomDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_customNamePrefix${user.uid}', name);
    
    // Notify listeners that the display name has changed
    _displayNameNotifier.value = name;
  }

  /// Get the ValueNotifier for display name changes
  static ValueNotifier<String?> get displayNameNotifier => _displayNameNotifier;

  /// Get custom display name (returns null if not set)
  static Future<String?> getCustomDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_customNamePrefix${user.uid}');
  }

  /// Clear custom display name (revert to Firebase displayName)
  static Future<void> clearCustomDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_customNamePrefix${user.uid}');
  }
}
