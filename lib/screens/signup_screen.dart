import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'signin_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isValidatingEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToSignin() {
    Navigator.pushReplacement(
      // ✅ CHANGED TO pushReplacement
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

  // Check if email domain is disposable/temporary
  Future<bool> _isDisposableEmail(String email) async {
    try {
      final domain = email.split('@')[1].toLowerCase();
      final response = await http
          .get(
            Uri.parse('https://open.kickbox.com/v1/disposable/$domain'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['disposable'] == true;
      }
    } catch (e) {
      print('Error checking disposable email: $e');
    }
    return false;
  }

  // Enhanced email validation with real-time checking
  Future<String?> _validateEmailWithApi(String email) async {
    if (email.isEmpty) return 'Please enter your email';

    // Basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email format';
    }

    // Check against common fake patterns
    if (!_isValidEmail(email)) {
      return 'Please enter a real email address';
    }

    setState(() => _isValidatingEmail = true);
    try {
      // Check if it's a disposable email
      final isDisposable = await _isDisposableEmail(email);
      if (isDisposable) {
        setState(() => _isValidatingEmail = false);
        return 'Temporary/disposable emails are not allowed';
      }

      // Check against common invalid domains
      final domain = email.split('@')[1].toLowerCase();
      final blockedDomains = [
        'tempmail.org',
        '10minutemail.com',
        'guerrillamail.com',
        'mailinator.com',
        'throwaway.email',
        'temp-mail.org',
        'example.com',
        'test.com',
        'invalid.com',
        'fake.com',
      ];

      if (blockedDomains.contains(domain)) {
        setState(() => _isValidatingEmail = false);
        return 'This email provider is not allowed';
      }
    } catch (e) {
      print('Email validation error: $e');
    } finally {
      setState(() => _isValidatingEmail = false);
    }

    return null;
  }

  // Enhanced client-side validation
  bool _isValidEmail(String email) {
    final lowercaseEmail = email.toLowerCase();

    // Block obvious fake patterns
    final invalidPatterns = [
      'test@',
      'fake@',
      'dummy@',
      'temp@',
      'trash@',
      'spam@',
      '@test.',
      '@fake.',
      '@dummy.',
      '@temp.',
      '@trash.',
      'asdf',
      'qwer',
      'zxcv',
      'hjkl',
      'random',
      'abc123',
      'aaaaa',
      'bbbbb',
      'ccccc',
      'ddddd',
      'eeeee',
    ];

    for (String pattern in invalidPatterns) {
      if (lowercaseEmail.contains(pattern)) return false;
    }

    return true;
  }

  // ✅ FIXED _submitForm method
  Future<void> _submitForm() async {
    // Validate email first
    final emailError = await _validateEmailWithApi(
      _emailController.text.trim(),
    );
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(emailError)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) _showEmailVerificationDialog();
    } catch (e) {
      // Only clear loading on error
      if (mounted) setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Signup failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    // ✅ No finally block - let dialog handle state
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Verify Your Email'),
            IconButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _navigateToSignin();
              },
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread,
                color: Color(0xFF1976D2),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification email to ${_emailController.text}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your email and click the verification link. The verification link will expire in 24 hours.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _authService.sendEmailVerification();
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Verification email sent!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Resend Email'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.reload();
              final user = FirebaseAuth.instance.currentUser;

              if (user != null && user.emailVerified) {
                Navigator.of(dialogContext).pop();
                _navigateToSignin();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Email verified successfully! Please sign in.'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Email not verified yet. Please check your email and try again.',
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('I\'ve Verified'),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED _signInWithGoogle method
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();

      // ✅ DON'T clear loading - AuthWrapper will handle redirect
      print('⏳ Waiting for AuthWrapper to redirect...');
    } catch (e) {
      // Only clear loading on error
      if (mounted) setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Google Sign-In failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    // ✅ No finally block - let AuthWrapper handle success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF1976D2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  40,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 12,
                    shadowColor: Colors.black.withAlpha(25),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo/Icon
                            Container(
                              width: 80,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2).withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 50,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              'Create your\nAccount',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign up to get started with Quiz Master',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Google Sign-In Button
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              icon: const Icon(Icons.g_mobiledata, size: 24),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Or',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Email Field with Real-time Validation
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                suffixIcon: _isValidatingEmail
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                                helperText:
                                    'We verify email addresses to prevent spam',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Please enter a valid email format';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                helperText: 'At least 6 characters',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Sign Up Button
                            ElevatedButton(
                              onPressed: (_isLoading || _isValidatingEmail)
                                  ? null
                                  : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Sign Up'),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Link
                            TextButton(
                              onPressed: _isLoading ? null : _navigateToSignin,
                              child: const Text(
                                'Already have an account? Sign In',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
