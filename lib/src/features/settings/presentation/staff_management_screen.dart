import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:dentaltid/src/features/settings/presentation/connection_settings_screen.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
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
        final staffService = ref.read(staffServiceProvider);
        _managedUsers = await staffService.getStaff(currentUser.uid);
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
          role == UserRole.assistant ? l10n.addAssistant : l10n.addReceptionist,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: l10n.username,
                hintText: l10n.enterUsername,
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
            child: Text(l10n.addStaff),
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
            // Inherit Subscription Status
            isPremium: currentUser.isPremium,
            trialStartDate: currentUser.trialStartDate,
            premiumExpiryDate: currentUser.premiumExpiryDate,
            
            isManagedUser: true,
            managedByDentistId: currentUser.uid,
            role: role,
            username: usernameController.text.trim(),
            pin: pinController.text.trim(),
          );

          final staffService = ref.read(staffServiceProvider);
          await staffService.addStaff(newStaff);
          await _loadManagedUsers(); // Refresh the list

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.staffAddedSuccess)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
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
        title: Text(l10n.deleteStaffTitle),
        content: Text(l10n.deleteStaffConfirm(staff.username ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final staffService = ref.read(staffServiceProvider);
        await staffService.deleteStaff(staff.uid);
        await _loadManagedUsers(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.staffRemovedSuccess)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStaffPin(UserProfile staff) async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePin),
        content: TextField(
          controller: pinController,
          decoration: InputDecoration(
            labelText: l10n.newPin,
            hintText: '0000-9999',
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.updatePin),
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
        final staffService = ref.read(staffServiceProvider);
        await staffService.updateStaff(updatedStaff);
        await _loadManagedUsers(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pinUpdatedSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getLocalizedRole(UserRole role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.dentist:
        return l10n.roleDentist;
      case UserRole.assistant:
        return l10n.roleAssistant;
      case UserRole.receptionist:
        return l10n.roleReceptionist;
      case UserRole.developer:
        return l10n.roleDeveloper;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConnectionSettingsScreen(),
                ),
              );
            },
            tooltip: 'Connection Settings',
          ),
        ],
      ),
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
                          label: Text(l10n.addAssistant),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addNewStaff(UserRole.receptionist),
                          icon: const Icon(Icons.person_add),
                          label: Text(l10n.addReceptionist),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.currentStaff,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _managedUsers.isEmpty
                        ? Center(
                            child: Text(l10n.noStaffAdded),
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
                                    '${_getLocalizedRole(staff.role, l10n)} • PIN: ${staff.pin}',
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
                                      PopupMenuItem(
                                        value: 'change_pin',
                                        child: Text(l10n.changePin),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(l10n.removeStaff),
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