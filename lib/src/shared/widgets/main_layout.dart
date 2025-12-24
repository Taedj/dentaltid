import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  UserRole _currentUserRole = UserRole.receptionist; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    await SettingsService.instance.init();
    final roleString = SettingsService.instance.getString('userRole');
    if (roleString != null) {
      if (mounted) {
        setState(() {
          _currentUserRole = UserRole.values.firstWhere(
            (e) => e.toString() == roleString,
            orElse: () => UserRole.receptionist,
          );
        });
      }
    }
  }

  Future<void> _handleTrialExpiration() async {
    // 1. Clear Remember Me
    await SettingsService.instance.setBool('remember_me', false);

    // 2. Sign Out Firebase (if online, best effort)
    await FirebaseAuth.instance.signOut();

    // 3. Redirect to Login and Show Dialog implies next login
    if (mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  int _calculateSelectedIndex(
    String location,
    List<NavigationRailDestination> destinations,
    AppLocalizations l10n,
  ) {
    // DEVELOPER Logic
    if (_currentUserRole == UserRole.developer) {
      if (location.endsWith('/users')) return 1;
      if (location.endsWith('/codes')) return 2;
      if (location.endsWith('/broadcasts')) return 3;
      if (location.startsWith('/settings')) return 4;
      return 0; // /developer overview
    }

    // DENTIST Logic
    if (location.startsWith('/patients')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.patients,
      );
    } else if (location.startsWith('/appointments')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.appointments,
      );
    } else if (location.startsWith('/inventory')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.inventory,
      );
    } else if (location.startsWith('/finance')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.finance,
      );
    } else if (location.startsWith('/settings')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.settings,
      );
    } else {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.dashboard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for Trial Expiration - this now serves as the primary license check
    ref.listen(userProfileProvider, (previous, next) {
      next.whenData((profile) async {
        if (profile == null) return;

        bool isExpired = false;
        // If the user is staff, check the dentist's inherited profile status
        if (profile.isManagedUser) {
          final dentistProfileJson = SettingsService.instance.getString(
            'dentist_profile',
          );
          if (dentistProfileJson != null) {
            final dentistProfile = UserProfile.fromJson(
              jsonDecode(dentistProfileJson),
            );
            if (dentistProfile.isTrialExpired) {
              isExpired = true;
            }
          }
        } else {
          // It's a dentist, check their own profile
          if (profile.isTrialExpired) {
            isExpired = true;
          }
        }

        if (isExpired) {
          _handleTrialExpiration();
        }
      });
    });

    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();

    final List<NavigationRailDestination> destinations = [];

    // --- DESTINATION BUILDER ---
    if (_currentUserRole == UserRole.developer) {
      // Developer Sidebar
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Overview'),
        ),
      );
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: Text('Users'),
        ),
      );
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.vpn_key_outlined),
          selectedIcon: Icon(Icons.vpn_key),
          label: Text('Codes'),
        ),
      );
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: Text('Broadcasts'),
        ),
      );
    } else {
      // Dentist Sidebar
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: Text(l10n.dashboard),
        ),
      );
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.people_outline),
          selectedIcon: const Icon(Icons.people),
          label: Text(l10n.patients),
        ),
      );
      if (_currentUserRole == UserRole.dentist ||
          _currentUserRole == UserRole.receptionist ||
          _currentUserRole == UserRole.assistant) {
        destinations.add(
          NavigationRailDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: Text(l10n.appointments),
          ),
        );
      }
      if (_currentUserRole == UserRole.dentist ||
          _currentUserRole == UserRole.assistant) {
        destinations.add(
          NavigationRailDestination(
            icon: const Icon(Icons.inventory_outlined),
            selectedIcon: const Icon(Icons.inventory),
            label: Text(l10n.inventory),
          ),
        );
      }
      if (_currentUserRole == UserRole.dentist) {
        destinations.add(
          NavigationRailDestination(
            icon: const Icon(Icons.assessment_outlined),
            selectedIcon: const Icon(Icons.assessment),
            label: Text(l10n.finance),
          ),
        );
      }
    }

    // Settings is Common
    destinations.add(
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: Text(l10n.settings),
      ),
    );

    int selectedIndex = _calculateSelectedIndex(location, destinations, l10n);
    // Safety check for index out of bounds
    if (selectedIndex < 0 || selectedIndex >= destinations.length) {
      selectedIndex = 0;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final networkStatus = ref.watch(networkStatusProvider);

    bool isOnline =
        (_currentUserRole == UserRole.dentist &&
            networkStatus == ConnectionStatus.serverRunning) ||
        (_currentUserRole != UserRole.dentist &&
            networkStatus == ConnectionStatus.synced);

    Color statusColor = isOnline
        ? Colors.green
        : (_currentUserRole == UserRole.dentist &&
                  networkStatus == ConnectionStatus.serverStopped
              ? Colors.grey
              : Colors.red);
    String statusTooltip = isOnline
        ? (_currentUserRole == UserRole.dentist
              ? 'Server Online'
              : 'Connected to Server')
        : 'Offline';

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.8,
                      ),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    String route = '/'; // Default

                    if (_currentUserRole == UserRole.developer) {
                      switch (index) {
                        case 0:
                          route = '/developer';
                          break;
                        case 1:
                          route = '/developer/users';
                          break;
                        case 2:
                          route = '/developer/codes';
                          break;
                        case 3:
                          route = '/developer/broadcasts';
                          break;
                        case 4:
                          route = '/settings';
                          break; // Settings is always last
                      }
                    } else {
                      // Dentist Logic
                      final destinationLabel =
                          (destinations[index].label as Text).data;
                      if (destinationLabel == l10n.patients) {
                        route = '/patients';
                      } else if (destinationLabel == l10n.appointments) {
                        route = '/appointments';
                      } else if (destinationLabel == l10n.inventory) {
                        route = '/inventory';
                      } else if (destinationLabel == l10n.finance) {
                        route = '/finance';
                      } else if (destinationLabel == l10n.settings) {
                        if (_currentUserRole != UserRole.dentist) {
                          route = '/staff-settings';
                        } else {
                          route = '/settings';
                        }
                      } else {
                        route = '/';
                      }
                    }

                    GoRouter.of(context).go(route);
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.transparent,
                  selectedLabelTextStyle: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  selectedIconTheme: IconThemeData(
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minWidth: 80,
                  groupAlignment: 0.0,
                  destinations: destinations.map((destination) {
                    return NavigationRailDestination(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                        ),
                        child: destination.icon,
                      ),
                      selectedIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                        child: destination.selectedIcon,
                      ),
                      label: destination.label,
                    );
                  }).toList(),
                ),
              ),
              Container(
                width: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.outline.withValues(alpha: 0.3),
                      colorScheme.outline.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Main Content Area
              Expanded(child: widget.child),
            ],
          ),
          Positioned(
            top: 8,
            right: 16,
            child: Tooltip(
              message: statusTooltip,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 127),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
