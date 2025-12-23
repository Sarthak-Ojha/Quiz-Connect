import 'package:flutter/material.dart';
import '../widgets/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _showGetStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animations
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    if (!mounted) return;
    
    // Start rotation animation
    _rotationController.repeat();
    
    // Wait for loading simulation
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    // Stop rotation and show get started
    _rotationController.stop();
    setState(() {
      _showGetStarted = true;
    });
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Revolving Question Mark
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 2 * 3.14159,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // App Title
                        const Text(
                          'Quiz Connect',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Test Your Knowledge',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        if (!_showGetStarted) ...[
                          const SizedBox(height: 60),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Get Started Button
                if (_showGetStarted)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ElevatedButton(
                              onPressed: _navigateToAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1976D2),
                                elevation: 8,
                                shadowColor: Colors.black.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
