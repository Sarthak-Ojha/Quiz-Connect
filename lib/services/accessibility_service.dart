import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Check if the platform is iOS
  bool get isIOS => Theme.of(navigatorKey.currentContext!).platform == TargetPlatform.iOS;

  // Navigation key for accessing context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize accessibility features
  Future<void> initialize() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  // Show accessibility dialog
  Future<void> showAccessibilityDialog() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add accessibility options here
            // Example: Text size, contrast, etc.
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Get text style with accessibility considerations
  TextStyle getAccessibleTextStyle({
    required BuildContext context,
    required TextStyle baseStyle,
    bool isBold = false,
    bool isItalic = false,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final fontSize = baseStyle.fontSize ?? 14.0;
    final scaledFontSize = fontSize * textScaleFactor;

    return baseStyle.copyWith(
      fontSize: scaledFontSize,
      fontWeight: isBold ? FontWeight.bold : baseStyle.fontWeight,
      fontStyle: isItalic ? FontStyle.italic : baseStyle.fontStyle,
    );
  }

  // Get accessible button style
  ButtonStyle getAccessibleButtonStyle({
    required BuildContext context,
    required Color backgroundColor,
    required Color foregroundColor,
    double? minimumSize,
  }) {
    final size = minimumSize ?? 48.0;
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: Size(size, size),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: foregroundColor,
      ),
    );
  }

  // Get accessible input decoration
  InputDecoration getAccessibleInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required BuildContext context,
    String? errorText,
    bool isRequired = true,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}
