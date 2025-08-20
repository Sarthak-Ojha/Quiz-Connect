import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart'; // ADD THIS LINE

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final ThemeService _themeService = ThemeService(); // ADD THIS LINE
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    // Enable silent notifications automatically
    _enableSilentNotifications();
  }

  Future<void> _enableSilentNotifications() async {
    await _notificationService.enableSilentNotifications();
  }

  // UPDATED toggle method using theme service
  Future<void> _toggleDarkMode(bool value) async {
    await _themeService.setThemeMode(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
          backgroundColor: value ? Colors.grey[800] : const Color(0xFF1976D2),
        ),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performSignOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      debugPrint('✅ Sign out successful - AuthWrapper will handle navigation');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sign out failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // UPDATED to use theme service with ListenableBuilder
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF1976D2),
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? Text(
                                  user?.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Quiz Master',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Preferences Section
                Text(
                  'App Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(
                      _themeService.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: _themeService.isDarkMode
                          ? Colors.orange
                          : Colors.amber,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      _themeService.isDarkMode
                          ? 'Dark theme enabled'
                          : 'Light theme enabled',
                    ),
                    trailing: Switch(
                      value: _themeService.isDarkMode,
                      onChanged: _toggleDarkMode,
                      activeColor: const Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quiz Settings Section
                Text(
                  'Quiz Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: Color(0xFF1976D2),
                    ),
                    title: const Text('Quiz Rules'),
                    subtitle: const Text(
                      'Learn how to play and scoring system',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showQuizRulesDialog,
                  ),
                ),
                const SizedBox(height: 24),

                // Account Section
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: _isSigningOut
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout, color: Colors.red),
                    title: Text(_isSigningOut ? 'Signing out...' : 'Sign Out'),
                    subtitle: Text(
                      _isSigningOut
                          ? 'Please wait...'
                          : 'Sign out of your account',
                    ),
                    onTap: _isSigningOut ? null : _showSignOutDialog,
                  ),
                ),
                const SizedBox(height: 24),

                // About Section
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.info,
                          color: Color(0xFF1976D2),
                        ),
                        title: const Text('About Quiz Master'),
                        subtitle: const Text('Version 1.0.0'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showAboutDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.privacy_tip,
                          color: Color(0xFF1976D2),
                        ),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showPrivacyPolicyDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.description,
                          color: Color(0xFF1976D2),
                        ),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showTermsOfServiceDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQuizRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.quiz, color: Color(0xFF1976D2)),
            SizedBox(width: 8),
            Text('Quiz Rules'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📚 How to Play:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Choose Category Mode for focused learning'),
              Text('• Pick Quick Mode for timed challenges'),
              SizedBox(height: 12),
              Text(
                '🏆 Scoring System:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Each correct answer = 10 points'),
              Text('• No penalty for wrong answers'),
              Text('• Quick Mode: 15 seconds per question'),
              Text('• Category Mode: No time limit'),
              SizedBox(height: 12),
              Text(
                '📊 Progress Tracking:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• All scores are automatically saved'),
              Text('• View detailed history in My Scores'),
              Text('• Track performance across categories'),
              Text('• Challenge yourself to beat your best!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.quiz, color: Color(0xFF1976D2)),
            SizedBox(width: 8),
            Text('About Quiz Master'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Master v1.0.0',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'A comprehensive quiz application designed to make learning fun and engaging. Test your knowledge across various categories and track your progress over time.',
            ),
            SizedBox(height: 12),
            Text('✨ Features:'),
            Text('• Multiple quiz categories'),
            Text('• Timed and untimed modes'),
            Text('• Progress tracking'),
            Text('• Detailed score history'),
            Text('• Smart notifications'),
            Text('• Dark/Light theme support'),
            SizedBox(height: 12),
            Text('Built with Flutter & Firebase'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We respect your privacy and are committed to protecting your personal data. '
            'Quiz Master collects only the necessary information to provide you with the best learning experience.\n\n'
            'Information we collect:\n'
            '• Account information (email, name)\n'
            '• Quiz scores and progress data\n'
            '• App preferences and settings\n\n'
            'How we use your information:\n'
            '• To provide personalized quiz experiences\n'
            '• To track and display your progress\n'
            '• To send helpful reminders\n'
            '• To improve app functionality\n\n'
            'Your data is stored securely and is never shared with third parties without your consent.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Quiz Master, you agree to these terms of service.\n\n'
            'Acceptable Use:\n'
            '• Use the app for educational and entertainment purposes\n'
            '• Do not attempt to cheat or exploit the quiz system\n'
            '• Respect other users and maintain appropriate conduct\n\n'
            'Account Responsibilities:\n'
            '• Keep your login credentials secure\n'
            '• Provide accurate information during registration\n'
            '• Notify us of any unauthorized account access\n\n'
            'The app is provided "as is" for educational and entertainment purposes. '
            'We strive to ensure accuracy of quiz content but cannot guarantee 100% accuracy. '
            'Please use the app responsibly and enjoy learning!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
