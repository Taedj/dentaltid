import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:dentaltid/src/core/remote_config_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  UserRole _currentUserRole = UserRole.receptionist; // Default role
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    await SettingsService.instance.init();
    // Initialize Remote Config in background (fire and forget)
    RemoteConfigService().fetchAndCacheConfig();

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
    } else if (location.startsWith('/advanced')) {
      return destinations.indexWhere(
        (destination) => (destination.label as Text).data == l10n.advanced,
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
    final userProfile = ref.watch(userProfileProvider).value;
    final usage = ref.watch(clinicUsageProvider);
    final l10n = AppLocalizations.of(context)!;

    final location = GoRouterState.of(context).uri.toString();

    // Handle Subscription/Trial Expiration Blocking
    // ONLY show if expired AND NOT already on settings AND not already showing
    // AND user is NOT a developer
    if (usage.isExpired && !location.startsWith('/settings') && !_isDialogShowing && _currentUserRole != UserRole.developer) {
      _isDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.timer_off_outlined, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(l10n.trialExpired),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUserRole == UserRole.dentist 
                      ? 'Your 30-day professional evaluation has ended. All clinical data has been safely locked.'
                      : l10n.staffActivationNotice,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please upgrade to a Premium or CROWN plan to restore full access to your clinic.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                if (_currentUserRole != UserRole.dentist)
                  TextButton(
                    onPressed: () {
                      SettingsService.instance.remove('managedUserProfile');
                      ref.invalidate(userProfileProvider);
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    child: Text(l10n.logout),
                  )
                else
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                    child: const Text('VIEW SETTINGS'),
                  ),
              ],
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isDialogShowing = false;
              });
            }
          });
        }
      });
    }

    final List<NavigationRailDestination> destinations = [];

    // --- DESTINATION BUILDER ---
    if (_currentUserRole == UserRole.developer) {
      // Developer Sidebar
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: Text(l10n.overviewMenu),
        ),
      );
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.group_outlined),
          selectedIcon: const Icon(Icons.group),
          label: Text(l10n.usersMenu),
        ),
      );
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.vpn_key_outlined),
          selectedIcon: const Icon(Icons.vpn_key),
          label: Text(l10n.codesMenu),
        ),
      );
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign),
          label: Text(l10n.broadcastsMenu),
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
        destinations.add(
          NavigationRailDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: Text(l10n.advanced),
          ),
        );
      }
    }

    // IF EXPIRED: Remove all destinations except Settings for Dentist
    if (usage.isExpired && _currentUserRole == UserRole.dentist) {
      destinations.clear();
      // Keep only Settings
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
    final connectedStaff = ref.watch(connectedStaffNamesProvider);

    String statusTooltip = l10n.offline;
    if (isOnline) {
      if (_currentUserRole == UserRole.dentist) {
        if (connectedStaff.isEmpty) {
          statusTooltip = l10n.serverOnlineNoStaff;
        } else {
          statusTooltip =
              '${l10n.serverOnlineWithStaffCount(connectedStaff.length)}\n${l10n.staffConnectedList(connectedStaff.join(', '))}';
        }
      } else {
        statusTooltip = l10n.connectedToServer;
      }
    }

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
                child: RepaintBoundary(
                  child: NavigationRail(
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/DT!d.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
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
                      } else if (destinationLabel == l10n.advanced) {
                        // EXPLICIT BLOCK: Only Trial and Enterprise (CROWN) have access.
                        // Professional (Premium) is blocked. Developers bypass.
                        final plan = userProfile?.plan;
                        final isAllowed = plan == SubscriptionPlan.trial || 
                                         plan == SubscriptionPlan.enterprise || 
                                         _currentUserRole == UserRole.developer;

                        if (!isAllowed) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Row(
                                children: [
                                  Icon(Icons.diamond_outlined, color: Colors.purpleAccent),
                                  SizedBox(width: 12),
                                  Text('CROWN / Trial Feature'),
                                ],
                              ),
                              content: const Text(
                                'Advanced insights and analytics are only available in the CROWN plan or during your 30-day Trial period.\n\nPlease upgrade your plan to access this feature.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(l10n.okButton),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        route = '/advanced';
                      } else if (destinationLabel == l10n.settings) {
                        if (_currentUserRole != UserRole.dentist) {
                          route = '/staff-settings';
                        } else {
                          route = '/settings';
                        }
                      } else {
                        // Prevent navigation if expired (Developers bypass)
                        if (usage.isExpired && !usage.isPremium &&
                            _currentUserRole == UserRole.dentist) {
                          return;
                        }
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: destination.selectedIcon,
                        ),
                        label: destination.label,
                      );
                    }).toList(),
                  ),
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
              Expanded(child: RepaintBoundary(child: widget.child)),
            ],
          ),
          if (location == '/')
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
