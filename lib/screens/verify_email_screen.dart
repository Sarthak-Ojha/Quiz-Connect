import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isEmailSent = false;
  bool _isLoading = false;
  bool _isSigningOut = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  bool _hasRedirected = false;
  Timer? _timer;
  Timer? _cooldownTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _sendVerificationEmail();
    _startEmailVerificationCheck();
  }

  void _redirectToApp() {
    if (_hasRedirected || !mounted) return;
    _hasRedirected = true;
    _timer?.cancel();
    _cooldownTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Email verified successfully! Redirecting...'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate directly to Home; the auth wrapper will also land on Home on rebuild
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  // ✅ FIXED: Improved email verification check with proper reload
  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // ✅ CRITICAL: Force reload to get fresh data from Firebase servers
          await user.reload();

          // ✅ Get the refreshed user instance after reload
          final refreshedUser = FirebaseAuth.instance.currentUser;

          if (refreshedUser?.emailVerified ?? false) {
            timer.cancel();
            _cooldownTimer?.cancel();

            if (mounted) {
              _redirectToApp();
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking email verification: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        
        if (refreshedUser?.emailVerified ?? false) {
          if (mounted) _redirectToApp();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Email not verified yet. Please check your email and click the verification link.'),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error checking verification: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (_isLoading || !_canResend) return;
    setState(() => _isLoading = true);
    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        setState(() {
          _isEmailSent = true;
          _canResend = false;
          _resendCooldown = 60;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEmailSent
                        ? 'Verification email sent again!'
                        : 'Verification email sent!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        _startCooldownTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to send email: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
          if (_resendCooldown <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      _timer?.cancel();
      _cooldownTimer?.cancel();
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'your email';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Email Verification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  _isSigningOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout),
                          tooltip: 'Sign Out',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: const Color(0xFF1976D2),
                          ),
                        ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Email Icon
                        const Icon(
                          Icons.email,
                          size: 80,
                          color: Color(0xFF1976D2),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Verify Your Email',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'We sent an email to $userEmail.\nCheck your inbox and spam folder.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                        ),

                        const SizedBox(height: 32),

                        // I've Verified Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checkEmailVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "I've Verified",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Resend Email Button
                        TextButton(
                          onPressed: _canResend && !_isLoading
                              ? _sendVerificationEmail
                              : null,
                          child: Text(
                            _isLoading
                                ? 'Sending...'
                                : _canResend
                                ? 'Resend Email'
                                : 'Resend in ${_resendCooldown}s',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
