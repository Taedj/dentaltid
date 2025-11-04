import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/features/security/domain/user_role.dart';

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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
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
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
