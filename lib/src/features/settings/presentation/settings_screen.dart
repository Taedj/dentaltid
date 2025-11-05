import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dentaltid/src/core/currency_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

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
                'Local Backup',
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
                                    ? 'Backup created at: $filePath'
                                    : 'Backup failed or cancelled.',
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
                    : const Text('Create Local Backup'),
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
                                    ? 'Backup restored successfully.'
                                    : 'Restore failed or cancelled.',
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
                    : const Text('Restore from Local Backup'),
              ),
              const Divider(height: 40),
              Text(
                'Cloud Sync',
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
                        final backupId = await backupService.createBackup(
                          uploadToFirebase: true,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                backupId != null
                                    ? 'Backup uploaded to Cloud with ID: $backupId'
                                    : 'Cloud backup failed.',
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
                    : const Text('Sync to Cloud'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  context.go('/settings/cloud-backups');
                },
                child: const Text('Manage Cloud Backups'),
              ),
              const Divider(height: 40),
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              DropdownButton<Locale>(
                value: ref.watch(languageProvider),
                onChanged: (Locale? newValue) {
                  if (newValue != null) {
                    ref.read(languageProvider.notifier).setLocale(newValue);
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
                'Currency',
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
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isAuthenticated', false);
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
