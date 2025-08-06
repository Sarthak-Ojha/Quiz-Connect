// lib/widgets/exit_confirmation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExitConfirmationWrapper extends StatefulWidget {
  // Changed to StatefulWidget
  final Widget child;
  final String title;
  final String message;
  final bool enableDoubleBackToExit;

  const ExitConfirmationWrapper({
    // Now const is valid since all fields are final
    required this.child,
    this.title = 'Exit Quiz Master',
    this.message = 'Are you sure you want to exit the app?',
    this.enableDoubleBackToExit = false,
    super.key,
  });

  @override
  State<ExitConfirmationWrapper> createState() =>
      _ExitConfirmationWrapperState();
}

class _ExitConfirmationWrapperState extends State<ExitConfirmationWrapper> {
  DateTime? _lastBackPressed; // Now this is an instance variable of the State

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Updated for Material 3
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Fixed: Use onPopInvokedWithResult instead of deprecated onPopInvoked
        if (!didPop) {
          final shouldExit = widget.enableDoubleBackToExit
              ? await _handleDoubleBackToExit()
              : await _showExitDialog();

          if (shouldExit && mounted) {
            // Use mounted directly in StatefulWidget
            SystemNavigator.pop();
          }
        }
      },
      child: widget.child,
    );
  }

  Future<bool> _showExitDialog() async {
    if (!mounted) return false; // Check mounted before showing dialog

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.exit_to_app,
            color: Colors.orange.shade700,
            size: 28,
          ),
        ),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1976D2),
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Exit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<bool> _handleDoubleBackToExit() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      if (mounted) {
        // Check mounted before using context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Press back again to exit'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey.shade800,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }
}
