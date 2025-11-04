import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dentaltid/l10n/app_localizations.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              switch (index) {
                case 0:
                  GoRouter.of(context).go('/');
                  break;
                case 1:
                  GoRouter.of(context).go('/patients');
                  break;
                case 2:
                  GoRouter.of(context).go('/appointments');
                  break;
                case 3:
                  GoRouter.of(context).go('/inventory');
                  break;
                case 4:
                  GoRouter.of(context).go('/finance');
                  break;
                case 5:
                  GoRouter.of(context).go('/settings');
                  break;
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: <NavigationRailDestination>[
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
              NavigationRailDestination(
                icon: const Icon(Icons.calendar_today_outlined),
                selectedIcon: const Icon(Icons.calendar_today),
                label: Text(l10n.appointments),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inventory_outlined),
                selectedIcon: const Icon(Icons.inventory),
                label: Text(l10n.inventory),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.assessment_outlined),
                selectedIcon: const Icon(Icons.assessment),
                label: Text(l10n.finance),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(l10n.settings),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content Area
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
