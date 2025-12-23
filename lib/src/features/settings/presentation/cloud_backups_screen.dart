import 'package:dentaltid/src/core/backup_service.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/features/settings/domain/backup_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudBackupsScreen extends ConsumerStatefulWidget {
  const CloudBackupsScreen({super.key});

  @override
  ConsumerState<CloudBackupsScreen> createState() => _CloudBackupsScreenState();
}

class _CloudBackupsScreenState extends ConsumerState<CloudBackupsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final BackupService _backupService = BackupService();
  late Future<List<BackupInfo>> _backupsFuture;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      _backupsFuture = _firebaseService.getUserBackups(user.uid);
    } else {
      _backupsFuture = Future.value([]);
    }
    setState(() {});
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final user = _firebaseService.getCurrentUser();
                            final success = await _backupService.restoreBackup(
                              backupId: backup.id,
                              uid: user?.uid,
                              ref: ref,
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
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Cloud Backup'),
                                content: const Text(
                                  'Are you sure you want to delete this cloud backup? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              final user = _firebaseService.getCurrentUser();
                              if (user != null) {
                                try {
                                  await _firebaseService
                                      .deleteUserBackupFromFirestore(
                                        user.uid,
                                        backup.id,
                                      );
                                  await _loadBackups();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Backup deleted successfully.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to delete backup: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                        ),
                      ],
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
