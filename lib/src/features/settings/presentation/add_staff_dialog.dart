import 'dart:convert';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:dentaltid/src/features/settings/domain/staff_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddStaffDialog extends ConsumerStatefulWidget {
  final StaffUser? staffToEdit;

  const AddStaffDialog({super.key, this.staffToEdit});

  @override
  ConsumerState<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _pinController;
  StaffRole _selectedRole = StaffRole.receptionist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.staffToEdit?.fullName ?? '');
    _usernameController = TextEditingController(text: widget.staffToEdit?.username ?? '');
    _pinController = TextEditingController(text: widget.staffToEdit?.pin ?? '');
    if (widget.staffToEdit != null) {
      _selectedRole = widget.staffToEdit!.role;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    var staff = StaffUser(
      id: widget.staffToEdit?.id,
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      pin: _pinController.text.trim(),
      role: _selectedRole,
      createdAt: widget.staffToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.staffToEdit == null) {
        final newId = await ref.read(staffServiceProvider).addStaff(staff);
        staff = staff.copyWith(id: newId); 
        _broadcastChange(SyncAction.create, staff);
      } else {
        await ref.read(staffServiceProvider).updateStaff(staff);
        _broadcastChange(SyncAction.update, staff);
      }
      ref.invalidate(staffListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _broadcastChange(SyncAction action, StaffUser data) {
    final event = SyncEvent(
      table: 'staff_users',
      action: action,
      data: data.toJson(),
    );
    
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile?.role == UserRole.dentist) {
        ref.read(syncServerProvider).broadcast(jsonEncode(event.toJson()));
    } else {
        ref.read(syncClientProvider).send(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.staffToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Staff' : 'Add New Staff'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'PIN (4 Digits)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length != 4) return 'Must be 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StaffRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: StaffRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toStringValue().toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading ? const CircularProgressIndicator() : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
