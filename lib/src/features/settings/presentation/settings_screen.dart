import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/features/settings/application/finance_settings_provider.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/backup_service.dart';
import 'package:dentaltid/src/features/settings/presentation/network_config_dialog.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/staff_list_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dentaltid/src/features/imaging/application/nanopix_sync_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  final _serverPortController = TextEditingController();
  bool _autoStartServer = false;
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
  void initState() {
    super.initState();
    final settings = SettingsService.instance;
    _autoStartServer = settings.getBool('autoStartServer') ?? false;
    _serverPortController.text = settings.getString('serverPort') ?? '8080';
  }

  @override
  void dispose() {
    _serverPortController.dispose();
    super.dispose();
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
              // Backup & Restore - Restricted to Dentists
              userProfileAsync.when(
                data: (userProfile) {
                  final isDentist = userProfile?.role == UserRole.dentist;
                  if (!isDentist) return const SizedBox.shrink();

                  final isPremium = userProfile?.isPremium ?? false;

                  return Column(
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
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.localBackup),
                                    content: Text(l10n.localBackupConfirm),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l10n.confirm),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                setState(() {
                                  _isLoading = true;
                                });
                                final filePath = await backupService
                                    .createBackup();
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
                        onPressed: (_isLoading || !isPremium)
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                final success = await backupService
                                    .restoreBackup(ref: ref);
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
                            : Text(
                                isPremium
                                    ? l10n.restoreFromLocalBackup
                                    : "${l10n.restoreFromLocalBackup} (${l10n.premiumOnly})",
                              ),
                      ),
                      const Divider(height: 40),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const SizedBox(),
              ),

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
                        if (userProfile.isPremium) ...[
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(l10n.syncToCloud),
                                        content: Text(l10n.cloudSyncConfirm),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(l10n.confirm),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true) return;

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

                                    // Check backup limit (Max 3)
                                    final backups = await _firebaseService
                                        .getUserBackups(user.uid);
                                    if (backups.length >= 3) {
                                      if (context.mounted) {
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'Backup Limit Reached',
                                            ),
                                            content: const Text(
                                              'You have reached the maximum of 3 cloud backups.\n\nPlease delete an old backup to create a new one.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(l10n.cancel),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.go(
                                                    '/settings/cloud-backups',
                                                  );
                                                },
                                                child: Text(
                                                  l10n.manageCloudBackups,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_off, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(l10n.cloudSyncPremiumNotice),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 40),
                      ],

                      if (isDentist) ...[
                        Text(
                          l10n.staffManagement,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          title: Text(l10n.manageStaffMembers),
                          subtitle: Text(l10n.addStaffSubtitle),
                          leading: const Icon(Icons.people),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StaffListScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 40),

                        // LAN Sync Settings - for Dentist
                        Text(
                          l10n.lanSyncSettings,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: Text(l10n.autoStartServerLabel),
                          subtitle: Text(l10n.autoStartServerSubtitle),
                          value: _autoStartServer,
                          onChanged: (value) async {
                            setState(() => _autoStartServer = value);
                            await SettingsService.instance.setBool(
                              'autoStartServer',
                              value,
                            );
                          },
                          secondary: const Icon(Icons.sync_outlined),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextFormField(
                            controller: _serverPortController,
                            decoration: InputDecoration(
                              labelText: l10n.serverPortLabel,
                              helperText: l10n.defaultPortHelper,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) async {
                              await SettingsService.instance.setString(
                                'serverPort',
                                value,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          title: Text(l10n.advancedNetworkConfig),
                          subtitle: Text(l10n.advancedNetworkConfigSubtitle),
                          leading: const Icon(Icons.lan_outlined),
                          trailing: const Icon(Icons.settings),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => const NetworkConfigDialog(
                                userType: UserType.dentist,
                              ),
                            );
                          },
                        ),
                        const Divider(height: 40),

                        // Imaging Storage Settings
                        Text(
                          l10n.imagingStorage,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          title: Text(l10n.imagingStorageSettings),
                          subtitle: FutureBuilder<String?>(
                            future: Future.value(
                              SettingsService.instance.getString(
                                'imaging_storage_path',
                              ),
                            ),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? l10n.defaultImagingPath,
                              );
                            },
                          ),
                          leading: const Icon(Icons.folder_shared),
                          trailing: const Icon(Icons.edit),
                          onTap: () async {
                            final String? result = await FilePicker.platform
                                .getDirectoryPath();
                            if (result != null) {
                              await SettingsService.instance.setString(
                                'imaging_storage_path',
                                result,
                              );
                              setState(() {}); // Rebuild to show new path
                            }
                          },
                        ),
                        const Divider(height: 40),

                        // NanoPix Sync Settings
                        Text(
                          l10n.nanopixSyncTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          title: Text(l10n.nanopixSyncPathLabel),
                          subtitle: FutureBuilder<String?>(
                            future: Future.value(
                              SettingsService.instance.getString(
                                'nanopix_sync_path',
                              ),
                            ),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? l10n.nanopixSyncPathNotSet,
                              );
                            },
                          ),
                          leading: const Icon(Icons.sync_alt),
                          trailing: const Icon(Icons.edit),
                          onTap: () async {
                            final String? result = await FilePicker.platform
                                .getDirectoryPath();
                            if (result != null) {
                              await SettingsService.instance.setString(
                                'nanopix_sync_path',
                                result,
                              );
                              setState(() {}); // Rebuild to show new path
                            }
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Live Bidirectional Sync'),
                          subtitle: const Text(
                            'Instantly sync patients and images between DentalTID and NanoPix',
                          ),
                          value: SettingsService.instance.getBool(
                                'nanopix_live_sync',
                              ) ??
                              false,
                          onChanged: (value) async {
                            await SettingsService.instance.setBool(
                              'nanopix_live_sync',
                              value,
                            );
                            if (value) {
                              ref.read(nanoPixSyncServiceProvider).startLiveSync();
                            } else {
                              ref.read(nanoPixSyncServiceProvider).stopLiveSync();
                            }
                            setState(() {});
                          },
                          secondary: const Icon(Icons.bolt),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            try {
                              await ref.read(nanoPixSyncServiceProvider).sync();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.nanopixSyncStarted),
                                ),
                              );
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Sync failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(l10n.nanopixSyncNowButton),
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
                          l10n.financeSettings,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SwitchListTile(
                          title: Text(l10n.includeInventoryCosts),
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
                          title: Text(l10n.includeAppointments),
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
                          title: Text(l10n.includeRecurringCharges),
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
                          title: Text(l10n.compactNumbers),
                          subtitle: Text(l10n.compactNumbersSubtitle),
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
                            decoration: InputDecoration(
                              labelText: l10n.monthlyBudgetCap,
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
                            decoration: InputDecoration(
                              labelText: l10n.taxRatePercentage,
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
                      if (userProfile != null && userProfile.plan != SubscriptionPlan.enterprise)
                        ElevatedButton.icon(
                          onPressed: () {
                            context.go('/settings/subscription-plans');
                          },
                          icon: const Icon(Icons.star, color: Colors.orange),
                          label: Text(l10n.activatePremium), // This now says "Upgrade your plan"
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withAlpha(30),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      if (userProfile != null && userProfile.plan != SubscriptionPlan.enterprise)
                        const SizedBox(height: 10),
                      const SizedBox(height: 10),

                      // Change Password - only for dentists
                      if (isDentist)
                        ElevatedButton(
                          onPressed: () =>
                              _showChangePasswordDialog(context, l10n),
                          child: Text(l10n.changePassword),
                        ),

                      const Divider(height: 40),
                      ElevatedButton(
                        onPressed: () async {
                          // Clear Local Persistence First
                          await SettingsService.instance.remove('remember_me');
                          await SettingsService.instance.remove(
                            'cached_user_profile',
                          );
                          await SettingsService.instance.remove(
                            'managedUserProfile',
                          );
                          await SettingsService.instance.remove('userRole');

                          await _firebaseService.signOut();
                          ref.invalidate(userProfileProvider);
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
                error: (error, stack) => Center(
                  child: Text(l10n.errorLoadingProfile(error.toString())),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
