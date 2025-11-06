import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/pin_service.dart';
import 'package:dentaltid/src/core/firebase_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  final PinService _pinService = PinService();
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _showSetupPinDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.setupPinCode),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  decoration: InputDecoration(labelText: l10n.enterNewPin),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pinRequired;
                    }
                    if (value.length != 4 ||
                        !RegExp(r'^\d{4}$').hasMatch(value)) {
                      return l10n.pinMustBe4Digits;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: confirmPinController,
                  decoration: InputDecoration(labelText: l10n.confirmNewPin),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pinRequired;
                    }
                    if (value != pinController.text) {
                      return l10n.pinsDoNotMatch;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                pinController.dispose();
                confirmPinController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.save),
              onPressed: () async {
                if (pinController.text == confirmPinController.text &&
                    pinController.text.length == 4 &&
                    RegExp(r'^\d{4}$').hasMatch(pinController.text)) {
                  final success = await _pinService.setupPinCode(
                    pinController.text,
                  );
                  if (context.mounted) {
                    pinController.dispose();
                    confirmPinController.dispose();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? l10n.pinSetupSuccessfully : l10n.invalidPin,
                        ),
                      ),
                    );
                    setState(() {}); // Refresh the UI
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.changePinCode),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPinController,
                  decoration: InputDecoration(labelText: l10n.enterCurrentPin),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                TextFormField(
                  controller: newPinController,
                  decoration: InputDecoration(labelText: l10n.enterNewPin),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                TextFormField(
                  controller: confirmPinController,
                  decoration: InputDecoration(labelText: l10n.confirmNewPin),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                currentPinController.dispose();
                newPinController.dispose();
                confirmPinController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.save),
              onPressed: () async {
                if (newPinController.text == confirmPinController.text &&
                    newPinController.text.length == 4 &&
                    RegExp(r'^\d{4}$').hasMatch(newPinController.text)) {
                  final success = await _pinService.changePinCode(
                    currentPinController.text,
                    newPinController.text,
                  );
                  if (context.mounted) {
                    currentPinController.dispose();
                    newPinController.dispose();
                    confirmPinController.dispose();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? l10n.pinChangedSuccessfully
                              : l10n.invalidPin,
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backupService = BackupService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.localBackup,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        final filePath = await backupService.createBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                filePath != null
                                    ? '${l10n.backupCreatedAt} $filePath'
                                    : l10n.backupFailedOrCancelled,
                              ),
                            ),
                          );
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.createLocalBackup),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        final success = await backupService.restoreBackup();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? l10n.backupRestoredSuccessfully
                                    : l10n.restoreFailedOrCancelled,
                              ),
                            ),
                          );
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.restoreFromLocalBackup),
              ),
              const Divider(height: 40),
              Text(
                l10n.cloudSync,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        final user = _firebaseService.getCurrentUser();

                        if (user == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.mustBeLoggedInToSync),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        final backupId = await backupService.createBackup(
                          uploadToFirebase: true,
                          uid: user.uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                backupId != null
                                    ? '${l10n.backupUploadedToCloud} $backupId'
                                    : l10n.cloudBackupFailed,
                              ),
                            ),
                          );
                        }
                        setState(() {
                          _isLoading = false;
                        });
                      },
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(l10n.syncToCloud),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  context.go('/settings/cloud-backups');
                },
                child: Text(l10n.manageCloudBackups),
              ),
              const Divider(height: 40),
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              DropdownButton<Locale>(
                value: ref.watch(languageProvider),
                onChanged: (Locale? newValue) async {
                  if (newValue != null) {
                    await ref
                        .read(languageProvider.notifier)
                        .setLocale(newValue);
                  }
                },
                items: const [Locale('en'), Locale('fr'), Locale('ar')]
                    .map<DropdownMenuItem<Locale>>((Locale value) {
                      return DropdownMenuItem<Locale>(
                        value: value,
                        child: Text(value.languageCode.toUpperCase()),
                      );
                    })
                    .toList(),
              ),
              const Divider(height: 40),
              Text(
                l10n.theme,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              DropdownButton<AppTheme>(
                value: ref.watch(themeProvider),
                onChanged: (AppTheme? newValue) {
                  if (newValue != null) {
                    ref.read(themeProvider.notifier).setTheme(newValue);
                  }
                },
                items: AppTheme.values.map<DropdownMenuItem<AppTheme>>((
                  AppTheme value,
                ) {
                  return DropdownMenuItem<AppTheme>(
                    value: value,
                    child: Text(value.toString().split('.').last),
                  );
                }).toList(),
              ),
              const Divider(height: 40),
              Text(
                l10n.currency,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: ref.watch(currencyProvider),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    ref.read(currencyProvider.notifier).setCurrency(newValue);
                  }
                },
                items: const ['£', '\$', 'DZD'].map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const Divider(height: 40),
              Text(
                l10n.pinCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              FutureBuilder<bool>(
                future: PinService().hasPinCode(),
                builder: (context, snapshot) {
                  final hasPin = snapshot.data ?? false;
                  return Column(
                    children: [
                      if (!hasPin)
                        ElevatedButton(
                          onPressed: () => _showSetupPinDialog(context, l10n),
                          child: Text(l10n.setupPinCode),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => _showChangePinDialog(context, l10n),
                          child: Text(l10n.changePinCode),
                        ),
                    ],
                  );
                },
              ),
              const Divider(height: 40),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isAuthenticated', false);
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
