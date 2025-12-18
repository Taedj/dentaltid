import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;

  List<UserProfile> _managedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadManagedUsers();
  }

  Future<void> _loadManagedUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await ref.read(userProfileProvider.future);
      if (currentUser != null) {
        // Load managed users from Firebase
        _managedUsers = await _firebaseService.getManagedUsers(currentUser.uid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading staff: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewStaff(UserRole role) async {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add ${role == UserRole.assistant ? 'Assistant' : 'Receptionist'}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username for staff member',
              ),
            ),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (4 digits)',
                hintText: '0000-9999',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );

    if (result == true &&
        usernameController.text.isNotEmpty &&
        pinController.text.length == 4) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = await ref.read(userProfileProvider.future);
        if (currentUser != null) {
          final newStaff = UserProfile(
            uid: _uuid.v4(),
            email: '', // Managed users don't use email
            licenseKey: currentUser.licenseKey, // Use dentist's license
            plan: currentUser.plan,
            status: currentUser.status,
            licenseExpiry: currentUser.licenseExpiry,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            lastSync: DateTime.now(),
            clinicName: currentUser.clinicName,
            dentistName: currentUser.dentistName,
            phoneNumber: currentUser.phoneNumber,
            medicalLicenseNumber: currentUser.medicalLicenseNumber,
            isManagedUser: true,
            managedByDentistId: currentUser.uid,
            role: role,
            username: usernameController.text.trim(),
            pin: pinController.text.trim(),
          );

          await _firebaseService.saveManagedUser(newStaff);
          await _loadManagedUsers(); // Refresh the list

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Staff member added successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding staff: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteStaff(UserProfile staff) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Are you sure you want to remove ${staff.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _firebaseService.deleteManagedUser(staff.uid);
        await _loadManagedUsers(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Staff member removed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error removing staff: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStaffPin(UserProfile staff) async {
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            labelText: 'New PIN (4 digits)',
            hintText: '0000-9999',
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );

    if (result == true && pinController.text.length == 4) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedStaff = staff.copyWith(pin: pinController.text.trim());
        await _firebaseService.saveManagedUser(updatedStaff);
        await _loadManagedUsers(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating PIN: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addNewStaff(UserRole.assistant),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Assistant'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addNewStaff(UserRole.receptionist),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Receptionist'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Current Staff',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _managedUsers.isEmpty
                        ? const Center(
                            child: Text('No staff members added yet'),
                          )
                        : ListView.builder(
                            itemCount: _managedUsers.length,
                            itemBuilder: (context, index) {
                              final staff = _managedUsers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        staff.role == UserRole.assistant
                                        ? Colors.blue
                                        : Colors.green,
                                    child: Icon(
                                      staff.role == UserRole.assistant
                                          ? Icons.medical_services
                                          : Icons.receipt,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(staff.username ?? 'Unknown'),
                                  subtitle: Text(
                                    '${staff.role.toString().split('.').last} • PIN: ${staff.pin}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'change_pin':
                                          _changeStaffPin(staff);
                                          break;
                                        case 'delete':
                                          _deleteStaff(staff);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'change_pin',
                                        child: Text('Change PIN'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Remove Staff'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
