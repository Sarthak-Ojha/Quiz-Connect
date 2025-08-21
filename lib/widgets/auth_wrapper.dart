import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth_selection_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 AuthWrapper: Building with current auth state');

    return StreamBuilder<User?>(
      // 🔧 CRITICAL: Use the proper stream type
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔧 ADD: Debug logging for stream states
        debugPrint(
          '🔍 AuthWrapper: Connection state: ${snapshot.connectionState}',
        );
        debugPrint('🔍 AuthWrapper: Has data: ${snapshot.hasData}');
        debugPrint('🔍 AuthWrapper: User: ${snapshot.data?.email}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('🔍 AuthWrapper: Showing splash screen (waiting)');
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper: Error - ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Authentication Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Force rebuild
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          debugPrint('✅ AuthWrapper: User authenticated - ${user.email}');

          final isGoogleUser = user.providerData.any(
            (p) => p.providerId == 'google.com',
          );

          if (user.emailVerified || isGoogleUser) {
            debugPrint('🏠 AuthWrapper: Navigating to HomeScreen');
            return const HomeScreen();
          } else {
            debugPrint('📧 AuthWrapper: Navigating to VerifyEmailScreen');
            return const VerifyEmailScreen();
          }
        }

        debugPrint('🔓 AuthWrapper: No user, showing AuthSelectionScreen');
        return const AuthSelectionScreen();
      },
    );
  }
}
