import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/auth_selection_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/home_screen.dart';

import 'widgets/exit_confirmation_wrapper.dart';

import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/firebase_analytics_service.dart';

import 'utils/seed_questions.dart';

// Debug function to export database for inspection
Future<void> exportDatabaseForInspection() async {
  try {
    final db = DatabaseService();
    await db.exportDatabaseForInspection();
  } catch (e, stackTrace) {
    debugPrint('❌ Error exporting database: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _reportError(details.exception, details.stack ?? StackTrace.current);
  };

  // Add error handling for platform channels
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error, stack);
    return true; // Prevent error from propagating
  };

  // Run the app in a zone to catch all unhandled exceptions and microtasks
  runZonedGuarded<Future<void>>(
    () async {
      try {
        // Initialize services
        await _initializeServices();
        
        // Run the app
        runApp(
          MaterialApp(
            builder: (context, child) => ErrorWidgetBuilder(child: QuizApp()),
          ),
        );
      } catch (e, stackTrace) {
        _handleStartupError(e, stackTrace);
      }
    },
    (error, stackTrace) => _handleZoneError(error, stackTrace),
  );
}

Future<void> _initializeServices() async {
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized successfully');

  // Initialize other services
  await Future.wait([
    _initAnalytics(),
    _initTheme(),
    _initNotifications(),
    _initDatabase(),
  ]);
}

Future<void> _initAnalytics() async {
  try {
    await FirebaseAnalyticsService.enableDebugMode();
    await FirebaseAnalyticsService.trackSessionStart();
    await FirebaseAnalyticsService.trackAchievement(
      achievementType: 'app_launch',
      achievementName: 'App Started',
      value: 1,
    );
    debugPrint('📊 Firebase Analytics initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error initializing analytics: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initTheme() async {
  try {
    await ThemeService().initialize();
    debugPrint('🎨 Theme service initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error initializing theme: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initNotifications() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.enableDailyChallengeNotifications();
    debugPrint('📱 Notification service initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error initializing notifications: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

Future<void> _initDatabase() async {
  try {
    final dbService = DatabaseService();
    await dbService.initializeDatabase();
    
    final seeded = await dbService.getSetting('questionsSeeded');
    if (seeded != 'true') {
      await seedQuestionsFromAsset();
      await dbService.insertSetting('questionsSeeded', 'true');
      debugPrint('✅ Questions seeded successfully');
    }
    
    debugPrint('💾 Database initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Error initializing database: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow; // Rethrow to be caught by the zone
  }
}

void _handleStartupError(dynamic error, StackTrace stackTrace) {
  debugPrint('❌ Fatal error during app startup: $error');
  debugPrint('Stack trace: $stackTrace');
  
  // Run the error app in a new zone to prevent recursive errors
  runZonedGuarded(
    () => runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    ),
    (error, stackTrace) => _handleZoneError(error, stackTrace),
  );
}

void _handleZoneError(dynamic error, StackTrace stackTrace) {
  debugPrint('⚠️ Uncaught error in zone: $error');
  debugPrint('Stack trace: $stackTrace');
  _reportError(error, stackTrace);
  
  // In debug mode, show error in console
  if (kDebugMode) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}

void _reportError(dynamic error, StackTrace stackTrace) {
  // Log the error with timestamp
  final timestamp = DateTime.now().toIso8601String();
  debugPrint('🚨 [$timestamp] Error reported: $error');
  
  // Print a more detailed stack trace in debug mode
  if (kDebugMode) {
    debugPrint('Stack trace: $stackTrace');
  }
  
  // Log the error type for better categorization
  debugPrint('Error type: ${error.runtimeType}');
  
  // Check if it's a common error type and provide more context
  if (error is FlutterError) {
    debugPrint('FlutterError details: ${error.diagnostics}');
  } else if (error is PlatformException) {
    debugPrint('PlatformException details: ${error.message}');
    debugPrint('Error code: ${error.code}');
    debugPrint('Error details: ${error.details}');
  }
  
  // Example: Send to Firebase Crashlytics if you have it set up
  // try {
  //   await FirebaseCrashlytics.instance.recordError(
  //     error,
  //     stackTrace,
  //     reason: 'a non-fatal error',
  //     information: ['Error occurred in microtask'],
  //   );
  // } catch (e) {
  //   debugPrint('Failed to report error to Crashlytics: $e');
  // }
}

/* Removed duplicate main() function to resolve 'main is already defined' error. 
   NotificationService().initialize() and enableSilentNotifications() are already called in the first main(). */

class ErrorWidgetBuilder extends StatelessWidget {
  final Widget child;

  const ErrorWidgetBuilder({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Set up the error widget builder
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return Material(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('An error occurred'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (kDebugMode) ...[
                  Text(
                    'Error: ${errorDetails.exception}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Stack trace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    errorDetails.stack.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ] else
                  const Text(
                    'The app encountered an error. Please restart the app and try again.',
                    style: TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Try to recover by popping the error screen
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        // If we can't pop, try to restart the app
                        runApp(const QuizApp());
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };

    // The actual widget tree
    return child;
  }
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Add error boundary for widget tree
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('An error occurred: ${errorDetails.exception}'),
            ),
          );
        };
        
        return child!;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF1976D2).withAlpha(77),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1976D2),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const ExitConfirmationWrapper(
        title: 'Exit Quiz Master?',
        message: 'Are you sure you want to exit the app?',
        child: SplashScreen(),
      ),
      routes: {
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignupScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/splash': (context) => const SplashScreen(),
        '/auth-selection': (context) => const AuthSelectionScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master - Error',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: ExitConfirmationWrapper(
        title: 'Close App?',
        message: 'The app encountered an error. Do you want to close it?',
        child: ErrorScreen(
          title: 'Initialization Error',
          message: 'Failed to initialize the app. Please try restarting.',
          error: error,
          onRetry: () {
            // Optional: add a restart mechanism
          },
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String error;
  final VoidCallback? onRetry;
  const ErrorScreen({
    super.key,
    required this.title,
    required this.message,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text('Error Details'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            error,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  '404',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Page Not Found',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
