import 'package:dentaltid/src/core/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:logging/logging.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dentistNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _medicalLicenseNumberController = TextEditingController();
  final _log = Logger('ProfileSettingsScreen');

  @override
  void initState() {
    super.initState();
    // It's better to populate controllers after the first build
    // to ensure the provider has the latest data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(userProfileProvider).asData?.value;
      if (userProfile != null) {
        _dentistNameController.text = userProfile.dentistName ?? '';
        _clinicNameController.text = userProfile.clinicName ?? '';
        _phoneNumberController.text = userProfile.phoneNumber ?? '';
        _medicalLicenseNumberController.text =
            userProfile.medicalLicenseNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _dentistNameController.dispose();
    _clinicNameController.dispose();
    _phoneNumberController.dispose();
    _medicalLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final firebaseService = ref.read(firebaseServiceProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _log.warning('Attempted to save profile, but no current user was found.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. User not logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProfile = ref.read(userProfileProvider).asData?.value;

    try {
      if (userProfile == null) {
        // Create new profile
        final newProfile = UserProfile(
          uid: currentUser.uid,
          email: currentUser.email!,
          dentistName: _dentistNameController.text,
          clinicName: _clinicNameController.text,
          phoneNumber: _phoneNumberController.text,
          medicalLicenseNumber: _medicalLicenseNumberController.text,
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.active,
          licenseKey: 'not-set', // Or generate a new one
          licenseExpiry: DateTime.now().add(const Duration(days: 36500)),
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          lastSync: DateTime.now(),
        );
        await firebaseService.createUserProfile(
          newProfile,
          newProfile.licenseKey,
        );
        _log.info('New user profile created successfully.');
      } else {
        // Update existing profile
        final updatedProfile = userProfile.copyWith(
          dentistName: _dentistNameController.text,
          clinicName: _clinicNameController.text,
          phoneNumber: _phoneNumberController.text,
          medicalLicenseNumber: _medicalLicenseNumberController.text,
        );
        await firebaseService.updateUserProfile(
          userProfile.uid,
          updatedProfile,
        );
        _log.info('User profile updated successfully.');
      }

      // Invalidate provider to refetch the updated data across the app
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _log.severe('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Doctor Profile')),
      body: userProfileAsync.when(
        data: (userProfile) {
          // Set initial values if they haven't been set yet
          if (userProfile != null) {
            if (_dentistNameController.text.isEmpty) {
              _dentistNameController.text = userProfile.dentistName ?? '';
            }
            if (_clinicNameController.text.isEmpty) {
              _clinicNameController.text = userProfile.clinicName ?? '';
            }
            if (_phoneNumberController.text.isEmpty) {
              _phoneNumberController.text = userProfile.phoneNumber ?? '';
            }
            if (_medicalLicenseNumberController.text.isEmpty) {
              _medicalLicenseNumberController.text =
                  userProfile.medicalLicenseNumber ?? '';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Update Your Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _dentistNameController,
                    decoration: const InputDecoration(
                      labelText: 'Dr. Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: const InputDecoration(
                      labelText: 'Clinic Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicalLicenseNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Medical License Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('Error loading profile: ${e.toString()}')),
      ),
    );
  }
}
