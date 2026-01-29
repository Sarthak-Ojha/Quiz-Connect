import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'firebase_analytics_service.dart';
import 'firestore_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Current Firebase user
  User? get currentUser => _auth.currentUser;

  // Firebase auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with Email/Password
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      debugPrint('🔐 Creating user account...');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      // Update the user's display name in Firebase Auth
      if (user != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
        debugPrint('👤 Updated display name to: $name');
      }

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('📧 Verification email sent');
      }

      debugPrint('✅ User account created: ${user?.uid}');

      // Sync user to local database
      if (user != null) {
        await _databaseService.syncFirebaseUser(
          user.uid,
          user.email ?? '',
          user.displayName,
          user.photoURL,
          user.emailVerified,
        );

        // Track user sign up in analytics
        await FirebaseAnalyticsService.trackUserSignUp('email');
        await FirebaseAnalyticsService.setUserProperties(
          userId: user.uid,
          displayName: user.displayName,
          email: user.email,
          emailVerified: user.emailVerified,
        );
      }

      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Sign in with Email/Password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
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
        final refreshedUser = _auth.currentUser!;
        debugPrint('📧 Email verified: ${refreshedUser.emailVerified}');

        // Check if email is verified
        if (!refreshedUser.emailVerified) {
          debugPrint('⚠️ Email not verified');
          return {
            'user': refreshedUser,
            'emailVerified': false,
            'message': 'Please verify your email address before signing in.'
          };
        }
      }

      // Sync user to local database
      if (user != null) {
        await _databaseService.syncFirebaseUser(
          user.uid,
          user.email ?? '',
          user.displayName,
          user.photoURL,
          user.emailVerified,
        );

        // Track user sign in in analytics
        await FirebaseAnalyticsService.trackUserSignIn('email');
      }

      debugPrint('🔄 Notifying listeners of auth state change');
      notifyListeners();
      return {
        'user': user,
        'emailVerified': user?.emailVerified ?? false,
        'message': 'Signed in successfully!'
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign in error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google sign-in...');

      // Initialize Google Sign-In with server client ID
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '308786259998-6av8vnh1qmu07r05ufremh14o2t1ivp4.apps.googleusercontent.com',
      );

      // Authenticate the user
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      debugPrint('✅ Google user obtained: ${googleUser.email}');

      // Get the authentication details
      final GoogleSignInClientAuthorization? authorization =
          await googleUser.authorizationClient.authorizationForScopes([
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ]);

      if (authorization == null) {
        debugPrint('❌ Failed to get authorization');
        return null;
      }

      debugPrint('✅ Google authentication obtained');
      debugPrint('🔑 Access Token: ${authorization.accessToken}');

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
      );

      debugPrint('🔑 Signing in with Google credential...');

      // Sign in to Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        debugPrint('✅ Successfully signed in with Google: ${user.uid}');

        // Sync user data with Firestore
        await DatabaseService().syncFirebaseUser(
          user.uid,
          user.email ?? '',
          user.displayName,
          user.photoURL,
          user.emailVerified,
        );

        // Track successful sign-in
        await FirebaseAnalyticsService.trackUserSignIn('google');

        return user;
      } else {
        debugPrint('❌ Failed to sign in with Google');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase auth error: ${e.code} - ${e.message}');
      throw Exception(_handleAuthException(e));
    } catch (e) {
      debugPrint('❌ Unexpected sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
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

  // Send email verification
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in.'};
      }

      if (user.emailVerified) {
        return {'success': true, 'message': 'Email is already verified.'};
      }

      await user.sendEmailVerification();
      debugPrint('📧 Email verification sent to: ${user.email}');

      return {
        'success': true,
        'message':
            'Verification email sent to ${user.email}. Please check your inbox.'
      };
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      return {
        'success': false,
        'message': 'Failed to send verification email. Please try again.'
      };
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
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

  // Sign out - Enhanced
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out...');

      // Sign out from Google
      try {
        await GoogleSignIn.instance.disconnect();
        debugPrint('✅ Google sign-out successful');
      } catch (e) {
        debugPrint('⚠️ Google sign-out error (non-critical): $e');
      }

      // Sign out from Firebase
      await _auth.signOut();
      debugPrint('✅ Firebase sign-out successful');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // Delete user account and associated data
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in.'};
      }

      final userId = user.uid;
      debugPrint('🗑️ Starting account deletion for user: $userId');

      // 1. Delete user from Firebase Authentication
      try {
        await user.delete();
        debugPrint('✅ User authentication account deleted');
      } on FirebaseAuthException catch (e) {
        // If user needs to re-authenticate, we'll handle that in the UI
        if (e.code == 'requires-recent-login') {
          debugPrint('⚠️ Re-authentication required for account deletion');
          return {
            'success': false,
            'requiresReauth': true,
            'message': 'Please sign in again to confirm account deletion.'
          };
        }
        rethrow;
      }

      // 2. Delete user data from leaderboard
      try {
        await FirestoreService.deleteUserFromLeaderboard(userId);
      } catch (e) {
        // Log the error but don't fail the entire operation
        debugPrint('⚠️ Error deleting user from leaderboard: $e');
      }

      // 3. Delete user profile / requests / invites from Firestore
      try {
        await FirestoreService.deleteUserData(userId);
      } catch (e) {
        debugPrint('⚠️ Error deleting user data from Firestore: $e');
      }

      // 4. Delete user data from local database
      try {
        await _databaseService.deleteUser(userId);
        debugPrint('✅ User data deleted from local database');
      } catch (e) {
        // Log the error but don't fail the entire operation
        debugPrint('⚠️ Error deleting user from local database: $e');
      }

      // 5. Sign out to clear any remaining state
      await signOut();

      debugPrint('✅ Account and all associated data deleted successfully');
      return {
        'success': true,
        'message': 'Your account and all associated data have been deleted.'
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Account deletion error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': _handleAuthException(e),
      };
    } catch (e) {
      debugPrint('❌ Unexpected error during account deletion: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // User info getters
  String? get userDisplayName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoURL => _auth.currentUser?.photoURL;
  bool get isSignedIn => _auth.currentUser != null;

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
