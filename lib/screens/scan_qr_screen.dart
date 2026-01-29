import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/database_service.dart';

class ScanQRCodeScreen extends StatefulWidget {
  const ScanQRCodeScreen({super.key});

  @override
  _ScanQRCodeScreenState createState() => _ScanQRCodeScreenState();
}

class _ScanQRCodeScreenState extends State<ScanQRCodeScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final DatabaseService _databaseService = DatabaseService();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _controller.switchCamera();
      setState(() {
        _cameraFacing = _cameraFacing == CameraFacing.back 
            ? CameraFacing.front 
            : CameraFacing.back;
      });
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.yellow : Colors.grey,
            ),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: Icon(
              _cameraFacing == CameraFacing.back 
                  ? Icons.camera_front 
                  : Icons.camera_rear,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              if (_isProcessing) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleScannedUser(barcode.rawValue ?? '');
                break; // Only process the first barcode
              }
            },
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _handleScannedUser(String scannedUserId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('Not authenticated');
      return;
    }

    if (scannedUserId == currentUser.uid) {
      _showError("You can't add yourself as a friend");
      return;
    }

    try {
      // Check if already friends
      final areFriends = await _databaseService.areFriends(currentUser.uid, scannedUserId);
      if (areFriends) {
        _showError('User is already your friend');
        return;
      }

      // Send friend request using DatabaseService
      final success = await _databaseService.sendFriendRequest(scannedUserId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
        Navigator.pop(context); // Return to previous screen
      } else {
        _showError('Could not send friend request. Check if already sent or user is already a friend.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
