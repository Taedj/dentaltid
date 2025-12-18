import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/user_model.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString('userRole');
    if (roleString != null) {
      setState(() {
        _currentUserRole = UserRole.values.firstWhere(
          (e) => e.toString() == roleString,
          orElse: () => UserRole.receptionist,
        );
      });
    }
  }

  int _calculateSelectedIndex(
    String location,
    List<NavigationRailDestination> destinations,
    AppLocalizations l10n,
  ) {
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
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.toString();

    final List<NavigationRailDestination> destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: Text(l10n.dashboard),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: Text(l10n.patients),
      ),
    ];

    if (_currentUserRole == UserRole.dentist ||
        _currentUserRole == UserRole.receptionist) {
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

    if (_currentUserRole == UserRole.dentist ||
        _currentUserRole == UserRole.receptionist) {
      destinations.add(
        NavigationRailDestination(
          icon: const Icon(Icons.assessment_outlined),
          selectedIcon: const Icon(Icons.assessment),
          label: Text(l10n.finance),
        ),
      );
    }

    destinations.add(
      NavigationRailDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: Text(l10n.settings),
      ),
    );

    int selectedIndex = _calculateSelectedIndex(location, destinations, l10n);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
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
                String route = '/'; // Default route
                if (index < destinations.length) {
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
                    route = '/settings';
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
    );
  }
}
