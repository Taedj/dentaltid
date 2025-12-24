import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart'; // Import UserType enum
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:dentaltid/src/features/settings/presentation/network_config_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';

class StaffSettingsScreen extends ConsumerWidget {
  const StaffSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<Locale>(
              value: ref.watch(languageProvider),
              onChanged: (Locale? newValue) async {
                if (newValue != null) {
                  await ref.read(languageProvider.notifier).setLocale(newValue);
                }
              },
              items: const [Locale('en'), Locale('fr'), Locale('ar')]
                  .map<DropdownMenuItem<Locale>>((Locale value) {
                    return DropdownMenuItem<Locale>(
                      value: value,
                      child: Text(value.languageCode.toUpperCase()),
                    );
                  })
                  .toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            trailing: DropdownButton<AppTheme>(
              value: ref.watch(themeProvider),
              onChanged: (AppTheme? newValue) {
                if (newValue != null) {
                  ref.read(themeProvider.notifier).setTheme(newValue);
                }
              },
              items: AppTheme.values.map<DropdownMenuItem<AppTheme>>((value) {
                return DropdownMenuItem<AppTheme>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            trailing: Text(
              ref.watch(currencyProvider),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Network'),
          ListTile(
            leading: const Icon(Icons.lan),
            title: const Text('LAN Connection Settings'),
            subtitle: const Text('Manage server connection'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) =>
                    const NetworkConfigDialog(userType: UserType.staff),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await SettingsService.instance.remove('remember_me');
              await SettingsService.instance.remove('managedUserProfile');
              await SettingsService.instance.remove('userRole');
              await SettingsService.instance.remove('cached_user_profile');
              await FirebaseAuth.instance.signOut();

              ref.invalidate(userProfileProvider);
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
