import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/auth_wrapper.dart';
import '../utils/seed_questions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  bool _isReseeding = false;
  String? _customDisplayName;

  @override
  void initState() {
    super.initState();
    _loadCustomDisplayName();
  }

  Future<void> _loadCustomDisplayName() async {
    final customName = await UserProfileService.getCustomDisplayName();
    if (mounted) {
      setState(() {
        _customDisplayName = customName;
      });
    }
  }

  Future<void> _saveCustomDisplayName(String name) async {
    await UserProfileService.saveCustomDisplayName(name);
    setState(() {
      _customDisplayName = name;
    });
  }

  String _getDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (_customDisplayName != null && _customDisplayName!.isNotEmpty) {
      return _customDisplayName!;
    }
    return user?.displayName ?? 'Quiz Master';
  }


  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Sign Out?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performSignOut();
            },
            child: const Text(
              'Yes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
    // Do async work first
    bool success = false;
    String? errorMessage;
    
    setState(() => _isSigningOut = true);
    
    try {
      debugPrint('🚪 Starting sign out process...');
      
      // All async work here
      await _authService.signOut();
      debugPrint('✅ AuthService.signOut() completed');
      success = true;
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      errorMessage = e.toString();
    }
    
    // Update state synchronously based on async results
    if (mounted) {
      setState(() => _isSigningOut = false);
      
      if (success) {
        debugPrint('🧭 Forcing immediate navigation to AuthWrapper...');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false, // Remove ALL previous routes
        );
      } else if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sign out failed: $errorMessage')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forceReseedQuestions() async {
    setState(() => _isReseeding = true);
    
    try {
      await forceReseedQuestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Questions reseeded successfully! Age categories should now work.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error reseeding questions: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReseeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                              ? NetworkImage(
                                  user!.photoURL!,
                                )
                              : null,
                          onBackgroundImageError: user?.photoURL != null
                              ? (exception, stackTrace) {
                                  // Handle network errors silently
                                }
                              : null,
                          child: Text(
                            (user?.displayName?.isNotEmpty == true)
                                ? user!.displayName!.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayName(),
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
                        IconButton(
                          onPressed: _showEditNameDialog,
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF1976D2),
                          ),
                          tooltip: 'Edit Name',
                        ),
                      ],
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
                // Developer Section
                Text(
                  'Developer Tools',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: _isReseeding
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, color: Color(0xFF1976D2)),
                    title: Text(_isReseeding ? 'Reseeding Database...' : 'Reseed Questions'),
                    subtitle: Text(
                      _isReseeding
                          ? 'Please wait while questions are reloaded'
                          : 'Force reload all quiz questions from assets',
                    ),
                    onTap: _isReseeding ? null : _forceReseedQuestions,
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
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = _getDisplayName();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF1976D2)),
            SizedBox(width: 8),
            Text('Edit Display Name'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your preferred display name:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              maxLength: 30,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _saveCustomDisplayName(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Display name updated successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
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
