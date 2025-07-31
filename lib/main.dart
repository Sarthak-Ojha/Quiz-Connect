import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Import screens and services
import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'services/database_service.dart';
import 'utils/seed_questions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: Improved error reporting
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  try {
    await Firebase.initializeApp();
    final dbService = DatabaseService();
    await dbService.initializeDatabase();

    // Prevent duplicate question inserts
    final seeded = await dbService.getSetting('questionsSeeded');
    if (seeded != 'true') {
      await seedQuestionsFromAsset();
      await dbService.insertSetting('questionsSeeded', 'true');
    }

    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
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
          shadowColor: Colors.black.withAlpha(25),
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
            shadowColor: Colors.blue.withAlpha(77),
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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/signin': (context) => const SigninScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/splash': (context) => const SplashScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const NotFoundScreen());
      },
    );
  }
}

// Error App for Firebase initialization errors
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
      home: ErrorScreen(
        title: 'Initialization Error',
        message: 'Failed to initialize the app. Please try restarting.',
        error: error,
        onRetry: () {
          // Optionally add restart logic here
        },
      ),
    );
  }
}

// 404 Not Found Screen and ErrorScreen should also be included as before
// ... (Keep your previous NotFoundScreen and ErrorScreen implementations here)
// 404 Not Found Screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
