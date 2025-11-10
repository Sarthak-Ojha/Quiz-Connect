import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/auth_service.dart';
import '../widgets/auth_wrapper.dart';
import 'signin_screen.dart';
import 'email_verification_screen.dart';

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
      context,
      MaterialPageRoute(builder: (context) => const SigninScreen()),
    );
  }

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
    } catch (_) {}
    return false;
  }

  bool _isValidEmailPattern(String email) {
    final lowercaseEmail = email.toLowerCase();
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
    ];
    for (final p in invalidPatterns) {
      if (lowercaseEmail.contains(p)) return false;
    }
    return true;
  }

  Future<String?> _validateEmailWithApi(String email) async {
    if (email.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email format';
    if (!_isValidEmailPattern(email)) {
      return 'Please enter a real email address';
    }

    setState(() => _isValidatingEmail = true);
    try {
      final isDisposable = await _isDisposableEmail(email);
      if (isDisposable) {
        return 'Temporary/disposable emails are not allowed';
      }

      final domain = email.split('@')[1].toLowerCase();
      const blockedDomains = {
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
      };
      if (blockedDomains.contains(domain)) {
        return 'This email provider is not allowed';
      }
    } catch (_) {
      // Ignore network validation errors for UX
    } finally {
      if (mounted) setState(() => _isValidatingEmail = false);
    }

    return null;
  }

  Future<void> _submitForm() async {
    final emailError = await _validateEmailWithApi(
      _emailController.text.trim(),
    );
    if (emailError != null) {
      if (!mounted) return;
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
      final user = await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted && user != null) {
        // Show verification screen instead of dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Signup failed: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Removed _showEmailVerificationDialog as we're now using the dedicated EmailVerificationScreen


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
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Center(
            child: Card(
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.1),
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
                      Container(
                        width: 80,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 50,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
          ),
        ),
      ),
    );
  }
}
