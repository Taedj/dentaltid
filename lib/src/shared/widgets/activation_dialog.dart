import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';

class ActivationDialog extends ConsumerStatefulWidget {
  final String uid;
  const ActivationDialog({super.key, required this.uid});

  @override
  ConsumerState<ActivationDialog> createState() => _ActivationDialogState();
}

class _ActivationDialogState extends ConsumerState<ActivationDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final code = _codeController.text.trim();
    if (code.length != 27) {
      setState(() => _error = 'Invalid code length (must be 27 characters)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final success = await firebaseService.redeemActivationCode(widget.uid, code);
      
      if (success) {
        if (mounted) {
          ref.invalidate(userProfileProvider); // Refresh profile
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account Activated Successfully! Premium features are now enabled.')),
          );
        }
      } else {
        setState(() => _error = 'Invalid or expired activation code');
      }
    } catch (e) {
      setState(() => _error = 'Error during activation: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // ignore: avoid_print
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Activation Required', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Your trial period has expired. Please enter a valid activation code to continue using DentalTid Premium.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Activation Code (27 chars)',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              maxLength: 27,
            ),
            const SizedBox(height: 16),
            Text('Need a code?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
             InkWell(
              onTap: () => _launchUrl('mailto:zitounitidjani@gmail.com'),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('zitounitidjani@gmail.com', style: GoogleFonts.poppins(color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl('tel:+213657293332'),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('+213 657 293 332', style: GoogleFonts.poppins(color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          TextButton(
            onPressed: () { 
                // Allow closing, but Auth logic will logout/kick user back if they try to proceed without valid license
               Navigator.of(context).pop(); 
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _activate,
            child: const Text('Activate'),
          ),
        ]
      ],
    );
  }
}
