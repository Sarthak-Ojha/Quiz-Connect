import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/auth_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This will permanently delete your account, friend requests, game invites, and profile data. This action cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteAccount();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAccount() async {
    if (_isDeletingAccount) return;

    setState(() => _isDeletingAccount = true);
    try {
      final result = await _authService.deleteAccount();
      if (!mounted) return;

      if (result['requiresReauth'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again to confirm deletion.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Account deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete account.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
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
    return user?.displayName ?? 'Quiz Connect';
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

  Future<void> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Exit?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ok'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('cancel'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      // Exit the app
      SystemNavigator.pop();
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
                  child: Column(
                    children: [
                      ListTile(
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
                      const Divider(height: 1),
                      ListTile(
                        leading: _isDeletingAccount
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever, color: Colors.red),
                        title: Text(_isDeletingAccount ? 'Deleting account...' : 'Delete Account'),
                        subtitle: const Text('Permanently remove your account and data'),
                        onTap: _isDeletingAccount ? null : _showDeleteAccountDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                        title: const Text('Exit App'),
                        subtitle: const Text('Close the application'),
                        onTap: _showExitConfirmationDialog,
                      ),
                    ],
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
                  child: ListTile(
                    leading: const Icon(
                      Icons.info,
                      color: Color(0xFF1976D2),
                    ),
                    title: const Text('Version 1.0.0'),
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
}