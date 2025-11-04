import 'package:dentaltid/src/core/backup_service.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/features/settings/domain/backup_info.dart';
import 'package:flutter/material.dart';

class CloudBackupsScreen extends StatefulWidget {
  const CloudBackupsScreen({super.key});

  @override
  State<CloudBackupsScreen> createState() => _CloudBackupsScreenState();
}

class _CloudBackupsScreenState extends State<CloudBackupsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final BackupService _backupService = BackupService();
  late Future<List<BackupInfo>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _backupsFuture = _firebaseService.getBackups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Backups')),
      body: FutureBuilder<List<BackupInfo>>(
        future: _backupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No cloud backups found.'));
          } else {
            final backups = snapshot.data!;
            return ListView.builder(
              itemCount: backups.length,
              itemBuilder: (context, index) {
                final backup = backups[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Backup from: ${backup.timestamp.toLocal()}'),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final success = await _backupService.restoreBackup(
                          backupId: backup.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Backup restored successfully.'
                                    : 'Restore failed.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Restore'),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
