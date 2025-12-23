import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'scan_qr_screen.dart';

class QRCodeScreen extends StatelessWidget {
  const QRCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanQRCodeScreen()),
              );
            },
            tooltip: 'Scan QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareQRCode(context, userId, displayName),
            tooltip: 'Share QR Code',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Profile
              Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null 
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // QR Code
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      QrImageView(
                        data: userId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Scan to add me as a friend',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // User ID with copy button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ID: ${userId.substring(0, 8)}...',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () async {
                              try {
                                await Clipboard.setData(ClipboardData(text: userId));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User ID copied to clipboard'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to copy to clipboard'),
                                  ),
                                );
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Copy User ID',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Share this QR code with friends to let them add you. '
                  'You can also share your user ID directly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQRCode(BuildContext context, String userId, String displayName) {
    final box = context.findRenderObject() as RenderBox?;
    final shareText = 'Add me as a friend on Quiz App!\n\n$userId';
    
    final origin = box != null 
        ? box.localToGlobal(Offset.zero) & box.size 
        : null;
        
    Share.share(
      shareText,
      subject: 'Add me as a friend',
      sharePositionOrigin: origin,
    );
  }
}
