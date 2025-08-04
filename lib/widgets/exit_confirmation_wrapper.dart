// lib/widgets/exit_confirmation_wrapper.dart
import 'package:flutter/material.dart';

class ExitConfirmationWrapper extends StatelessWidget {
  final Widget child;

  const ExitConfirmationWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.exit_to_app,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text('Exit App'),
              ],
            ),
            content: const Text(
              'Do you want to exit the app?',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Yes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: child,
    );
  }
}
