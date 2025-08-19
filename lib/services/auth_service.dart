import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

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
      print('🔐 Creating user account...');

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('📧 Verification email sent');
      }

      print('✅ User account created: ${user?.uid}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign up error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // ✅ SINGLE Sign in with Email/Password method with proper verification check
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Attempting email/password sign-in...');

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      print('✅ Firebase sign-in successful: ${user?.uid}');

      // ✅ Force reload to get fresh user data
      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;

        print('📧 Email verified: ${refreshedUser?.emailVerified}');

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          // Don't sign out immediately - let them verify first
          print(
            '⚠️ Email not verified, but keeping user signed in for verification flow',
          );
          // The AuthWrapper will redirect to VerifyEmailScreen
        }

        print('🔄 Notifying listeners of auth state change');
        notifyListeners();
        return refreshedUser;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Remember Me functionality
  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', remember);
    print('💾 Remember me set to: $remember');
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? false;
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google sign-in...');

      // Sign out first to prevent cached session issues
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google sign-in cancelled by user');
        return null; // User cancelled
      }

      print('✅ Google user obtained: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      print('✅ Firebase credential sign-in successful: ${user?.uid}');
      print('📧 Google user email verified: ${user?.emailVerified}');

      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ Google sign-in Firebase error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      print('❌ Google sign-in general error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print('📧 Email verification sent to: ${user.email}');
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
      print('📧 Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('❌ Password reset error: ${e.code} - ${e.message}');
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

  // Sign out
  Future<void> signOut() async {
    try {
      print('🚪 Signing out...');
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors
    }
    await _auth.signOut();
    print('✅ Sign out complete');
    notifyListeners();
  }

  // User info getters
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;
  bool get isSignedIn => _auth.currentUser != null;

  // Google sign-in status
  Future<bool> get isGoogleSignedIn async {
    return await _googleSignIn.isSignedIn();
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
