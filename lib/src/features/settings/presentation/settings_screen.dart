import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/backup_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/features/settings/application/finance_settings_provider.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';

import 'package:dentaltid/src/core/firebase_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.changePassword),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(labelText: l10n.currentPassword),
                  obscureText: true,
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  obscureText: true,
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.confirmNewPassword,
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(l10n.save),
              onPressed: () async {
                if (newPasswordController.text ==
                    confirmPasswordController.text) {
                  try {
                    await _firebaseService.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.passwordChangedSuccessfully),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.invalidPassword),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.passwordsDoNotMatch),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    final userProfileAsync = ref.watch(userProfileProvider);

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

              // Cloud Sync section - only for dentists
              userProfileAsync.when(
                data: (userProfile) {
                  final isDentist =
                      userProfile != null &&
                      userProfile.role == UserRole.dentist &&
                      !userProfile.isManagedUser;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isDentist) ...[
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
                                  final user = _firebaseService
                                      .getCurrentUser();

                                  if (user == null) {
                                    if (context.mounted) {
                                      context.go('/login');
                                    }
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    return;
                                  }

                                  final backupId = await backupService
                                      .createBackup(
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
                      ],

                      // Language settings - view-only for non-dentists
                      Text(
                        l10n.language,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      if (isDentist)
                        DropdownButton<Locale>(
                          value: ref.watch(languageProvider),
                          onChanged: (Locale? newValue) async {
                            if (newValue != null) {
                              await ref
                                  .read(languageProvider.notifier)
                                  .setLocale(newValue);
                            }
                          },
                          items:
                              const [
                                Locale('en'),
                                Locale('fr'),
                                Locale('ar'),
                              ].map<DropdownMenuItem<Locale>>((Locale value) {
                                return DropdownMenuItem<Locale>(
                                  value: value,
                                  child: Text(value.languageCode.toUpperCase()),
                                );
                              }).toList(),
                        )
                      else
                        Text(
                          ref
                              .watch(languageProvider)
                              .languageCode
                              .toUpperCase(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      const Divider(height: 40),

                      // Theme settings
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

                      // Currency settings - view-only for non-dentists
                      Text(
                        l10n.currency,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      if (isDentist)
                        DropdownButton<String>(
                          value: ref.watch(currencyProvider),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              ref
                                  .read(currencyProvider.notifier)
                                  .setCurrency(newValue);
                            }
                          },
                          items: const ['£', '\$', 'DZD']
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                        )
                      else
                        Text(
                          ref.watch(currencyProvider),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),

                      // Finance Settings - only for dentists
                      if (isDentist) ...[
                        const Divider(height: 40),
                        Text(
                          'Finance Settings',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SwitchListTile(
                          title: const Text('Include Inventory Costs'),
                          value: ref
                              .watch(financeSettingsProvider)
                              .includeInventory,
                          onChanged: (value) {
                            ref
                                .read(financeSettingsProvider.notifier)
                                .toggleInventory(value);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Include Appointments'),
                          value: ref
                              .watch(financeSettingsProvider)
                              .includeAppointments,
                          onChanged: (value) {
                            ref
                                .read(financeSettingsProvider.notifier)
                                .toggleAppointments(value);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Include Recurring Charges'),
                          value: ref
                              .watch(financeSettingsProvider)
                              .includeRecurring,
                          onChanged: (value) {
                            ref
                                .read(financeSettingsProvider.notifier)
                                .toggleRecurring(value);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Compact Numbers (e.g. 1K)'),
                          subtitle: const Text(
                            'Use short format for large numbers',
                          ),
                          value: ref
                              .watch(financeSettingsProvider)
                              .useCompactNumbers,
                          onChanged: (value) {
                            ref
                                .read(financeSettingsProvider.notifier)
                                .toggleCompactNumbers(value);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            initialValue:
                                ref
                                    .read(financeSettingsProvider)
                                    .monthlyBudgetCap
                                    ?.toString() ??
                                '',
                            decoration: const InputDecoration(
                              labelText: 'Monthly Budget Cap',
                              helperText: 'Leave empty for no limit',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) {
                              final budget = double.tryParse(value);
                              ref
                                  .read(financeSettingsProvider.notifier)
                                  .setMonthlyBudgetCap(budget);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            initialValue: ref
                                .read(financeSettingsProvider)
                                .taxRatePercentage
                                .toString(),
                            decoration: const InputDecoration(
                              labelText: 'Tax Rate (%)',
                              suffixText: '%',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) {
                              final rate = double.tryParse(value) ?? 0.0;
                              ref
                                  .read(financeSettingsProvider.notifier)
                                  .setTaxRatePercentage(rate);
                            },
                          ),
                        ),
                      ],

                      const Divider(height: 40),
                      Text(
                        l10n.account,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => context.go('/settings/profile'),
                        child: Text(l10n.editProfile),
                      ),
                      const SizedBox(height: 10),

                      // Change Password - only for dentists
                      if (isDentist)
                        ElevatedButton(
                          onPressed: () =>
                              _showChangePasswordDialog(context, l10n),
                          child: Text(l10n.changePassword),
                        ),

                      // Staff Management - only for dentists
                      if (isDentist) ...[
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/settings/staff-management'),
                          child: const Text('Staff Management'),
                        ),
                      ],

                      const Divider(height: 40),
                      ElevatedButton(
                        onPressed: () async {
                          await _firebaseService.signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: Text(l10n.logout),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Error loading user profile: $error')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
