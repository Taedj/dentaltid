import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/remote_config_service.dart';

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
      setState(() => _error = AppLocalizations.of(context)!.invalidCodeLength);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final success = await firebaseService.redeemActivationCode(
        widget.uid,
        code,
      );

      if (success) {
        if (mounted) {
          ref.invalidate(userProfileProvider); // Refresh profile
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.activationSuccess),
            ),
          );
        }
      } else {
        setState(
          () => _error = AppLocalizations.of(context)!.invalidActivationCode,
        );
      }
    } catch (e) {
      setState(
        () => _error = AppLocalizations.of(
          context,
        )!.activationError(e.toString()),
      );
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
    final remoteConfig = ref.watch(remoteConfigProvider).value;
    final supportEmail =
        remoteConfig?.supportEmail ?? 'zitounitidjani@gmail.com';
    final supportPhone = remoteConfig?.supportPhone ?? '+213657293332';

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.activationRequired,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.trialExpiredNotice,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.activationCodeLabel,
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              maxLength: 27,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.needACode,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl('mailto:$supportEmail'),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    supportEmail,
                    style: GoogleFonts.poppins(color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl(
                'https://wa.me/${supportPhone.replaceAll(RegExp(r"\s+"), "").replaceAll("+", "")}',
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    supportPhone,
                    style: GoogleFonts.poppins(color: Colors.green),
                  ),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: _activate,
            child: Text(AppLocalizations.of(context)!.activatePremium),
          ),
        ],
      ],
    );
  }
}
