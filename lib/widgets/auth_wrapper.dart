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
  bool _isInitialLoad = true;

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      // 🔧 CRITICAL: Use the proper stream type
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('🔄 AuthWrapper: Connection state: ${snapshot.connectionState}');
        debugPrint('🔄 AuthWrapper: Has data: ${snapshot.hasData}');
        debugPrint('🔄 AuthWrapper: User: ${snapshot.data?.uid}');

        // Only show splash screen on the very first load
        if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
          debugPrint('🔄 AuthWrapper: Showing splash screen');
          return const SplashScreen();
        }

        // Mark that we've completed the initial load
        if (snapshot.connectionState != ConnectionState.waiting) {
          _isInitialLoad = false;
        }

        if (snapshot.hasError) {
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
          debugPrint('🔄 AuthWrapper: User found - ${user.email}');

          final isGoogleUser = user.providerData.any(
            (p) => p.providerId == 'google.com',
          );
          debugPrint('🔄 AuthWrapper: Is Google user: $isGoogleUser');
          debugPrint('🔄 AuthWrapper: Email verified: ${user.emailVerified}');

          if (user.emailVerified || isGoogleUser) {
            debugPrint('🏠 AuthWrapper: Navigating to HomeScreen');
            return const HomeScreen();
          } else {
            debugPrint('📧 AuthWrapper: Navigating to VerifyEmailScreen');
            return const VerifyEmailScreen();
          }
        }
        debugPrint('🔐 AuthWrapper: No user found, showing AuthSelectionScreen');
        return const AuthSelectionScreen();
      },
    );
  }
}
