import 'dart:convert';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:dentaltid/src/features/settings/presentation/add_staff_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffListAsync = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddStaffDialog(),
              );
            },
          ),
        ],
      ),
      body: staffListAsync.when(
        data: (staffList) {
          if (staffList.isEmpty) {
            return const Center(child: Text('No staff members found.'));
          }
          return ListView.separated(
            itemCount: staffList.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(staff.fullName[0].toUpperCase()),
                ),
                title: Text(staff.fullName),
                subtitle: Text('${staff.role.toStringValue().toUpperCase()} • ${staff.username}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddStaffDialog(staffToEdit: staff),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Staff'),
                            content: Text('Are you sure you want to delete ${staff.fullName}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && staff.id != null) {
                          await ref.read(staffServiceProvider).deleteStaff(staff.id!);
                          
                          // Broadcast the delete event
                          final event = SyncEvent(
                            table: 'staff_users',
                            action: SyncAction.delete,
                            data: {'id': staff.id},
                          );
                          
                          final userProfile = ref.read(userProfileProvider).value;
                          if (userProfile?.role == UserRole.dentist) {
                              ref.read(syncServerProvider).broadcast(jsonEncode(event.toJson()));
                          } else {
                              ref.read(syncClientProvider).send(event);
                          }

                          ref.invalidate(staffListProvider);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
