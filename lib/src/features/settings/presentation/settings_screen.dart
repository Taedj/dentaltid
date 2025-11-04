import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupService = BackupService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: Padding(
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
              onPressed: () async {
                final filePath = await backupService.createBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(filePath != null ? 'Backup created at: $filePath' : 'Backup failed or cancelled.')),
                  );
                }
              },
              child: const Text('Create Local Backup'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final success = await backupService.restoreBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Backup restored successfully.' : 'Restore failed or cancelled.')),
                  );
                }
              },
              child: const Text('Restore from Local Backup'),
            ),
            const Divider(height: 40),
            Text(
              'Cloud Sync',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final backupId = await backupService.createBackup(uploadToFirebase: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(backupId != null ? 'Backup uploaded to Cloud with ID: $backupId' : 'Cloud backup failed.')),
                  );
                }
              },
              child: const Text('Sync to Cloud'),
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
              items: const [
                Locale('en'),
                Locale('fr'),
                Locale('ar'),
              ].map<DropdownMenuItem<Locale>>((Locale value) {
                return DropdownMenuItem<Locale>(
                  value: value,
                  child: Text(value.languageCode.toUpperCase()),
                );
              }).toList(),
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
              items: AppTheme.values.map<DropdownMenuItem<AppTheme>>((AppTheme value) {
                return DropdownMenuItem<AppTheme>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}