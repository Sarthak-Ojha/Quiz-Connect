import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Firebase auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with Email/Password
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔐 Creating user account...');

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('📧 Verification email sent');
      }

      debugPrint('✅ User account created: ${user?.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Sign in with Email/Password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔐 Attempting email/password sign-in...');

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      debugPrint('✅ Firebase sign-in successful: ${user?.uid}');

      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;

        debugPrint('📧 Email verified: ${refreshedUser?.emailVerified}');

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          debugPrint(
            '⚠️ Email not verified, but keeping user signed in for verification flow',
          );
        }

        debugPrint('🔄 Notifying listeners of auth state change');
        notifyListeners();
        return refreshedUser;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign in error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Remember Me functionality
  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', remember);
    debugPrint('💾 Remember me set to: $remember');
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  // Google Sign-In - UPDATED with your serverClientId
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google sign-in...');

      // Step 1: Initialize Google Sign In with your Web Client ID
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '308786259998-6av8vnh1qmu07r05ufremh14o2t1ivp4.apps.googleusercontent.com',
      );

      // Step 2: Authenticate the user
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      debugPrint('✅ Google user obtained: ${googleUser.email}');

      // Step 3: Get the authentication details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Step 4: Get authorization headers with null safety
      final Map<String, String>? authHeaders = await googleUser
          .authorizationClient
          .authorizationHeaders(['email', 'profile']);

      // Handle null case for authorization headers
      if (authHeaders == null) {
        debugPrint('❌ Failed to get authorization headers');
        throw Exception('Failed to get Google authorization');
      }

      // Step 5: Extract access token safely
      final String? bearerToken = authHeaders['Authorization'];
      final String? accessToken = bearerToken?.replaceFirst('Bearer ', '');

      if (accessToken == null) {
        debugPrint('❌ No access token found in authorization headers');
        throw Exception('Failed to get access token from Google');
      }

      // Step 6: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 7: Sign in to Firebase with the credential
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      debugPrint('✅ Firebase credential sign-in successful: ${user?.uid}');
      debugPrint('📧 Google user email verified: ${user?.emailVerified}');

      notifyListeners();
      return user;
    } on GoogleSignInException catch (e) {
      debugPrint('❌ Google sign-in error: ${e.code.name} - ${e.description}');
      throw Exception('Google sign-in failed: ${e.description}');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase auth error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      debugPrint('❌ Unexpected sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint('📧 Email verification sent to: ${user.email}');
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('📧 Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await user.reload();
      notifyListeners();
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      notifyListeners();
    }
  }

  // Re-authenticate for sensitive actions
  Future<void> reauthenticateWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Sign out - Updated for v7.x
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');

      // Sign out from Google
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    }

    // Sign out from Firebase
    await _auth.signOut();
    debugPrint('✅ Sign out complete');
    notifyListeners();
  }

  // User info getters
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;
  bool get isSignedIn => _auth.currentUser != null;

  // Google sign-in status
  Future<bool> get isGoogleSignedIn async {
    // Simplified approach - check Firebase auth state
    return _auth.currentUser != null;
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'user-not-found':
        return 'No user found for this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}
