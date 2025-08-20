import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/auth_selection_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/splash_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
          '🔄 AuthWrapper: Connection state = ${snapshot.connectionState}',
        );
        debugPrint('📱 AuthWrapper: Has data = ${snapshot.hasData}');
        debugPrint('👤 AuthWrapper: User = ${snapshot.data?.uid}');
        debugPrint(
          '📧 AuthWrapper: Email verified = ${snapshot.data?.emailVerified}',
        );

        // Show splash while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint(
            '⏳ AuthWrapper: Showing splash screen (waiting for auth state)',
          );
          return const SplashScreen();
        }

        // Handle stream errors
        if (snapshot.hasError) {
          debugPrint('❌ AuthWrapper: Auth stream error = ${snapshot.error}');
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
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          debugPrint('✅ AuthWrapper: User authenticated = ${user.uid}');
          debugPrint('📧 AuthWrapper: Email verified = ${user.emailVerified}');
          debugPrint(
            '🔍 AuthWrapper: Provider data = ${user.providerData.map((p) => p.providerId).toList()}',
          );

          // Check if email is verified OR if it's a Google sign-in user
          bool isEmailVerified = user.emailVerified;
          bool isGoogleUser = user.providerData.any(
            (info) => info.providerId == 'google.com',
          );

          if (isEmailVerified || isGoogleUser) {
            debugPrint('🏠 AuthWrapper: Navigating to HomeScreen');
            return const HomeScreen();
          } else {
            debugPrint('📨 AuthWrapper: Navigating to VerifyEmailScreen');
            return const VerifyEmailScreen();
          }
        }

        // If user is not logged in
        debugPrint(
          '🔐 AuthWrapper: No user authenticated, showing AuthSelectionScreen',
        );
        return const AuthSelectionScreen();
      },
    );
  }
}
