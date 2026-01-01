import 'package:dentaltid/src/features/developer/presentation/developer_broadcasts_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_codes_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_orders_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_overview_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DeveloperDashboardScreen extends ConsumerStatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  ConsumerState<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState
    extends ConsumerState<DeveloperDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // PRO Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: const Color(
              0xFF1A1C1E,
            ), // Dark professional background
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
            selectedLabelTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 11,
            ),
            useIndicator: true,
            indicatorColor: const Color(0xFF1E88E5), // Professional Blue
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: CircleAvatar(
                backgroundColor: Colors.white10,
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key),
                label: Text('Codes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: Text('Broadcasts'),
              ),
            ],
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: const Color(0xFFF0F2F5), // Light gray content background
              child: _buildScreen(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    // We wrap each screen in a consistent padding/container if needed,
    // or let them handle their own Scaffolds (which they do).
    // Since they have Scaffolds, we might get nested scaffolds, but likely fine
    // if we remove the AppBar there or just nest them.
    // For a cleaner look, the sub-screens should ideally NOT be Scaffolds if used here,
    // OR this dashboard shouldn't be a Scaffold if the children are.
    // Given the previous architecture, they are Scaffolds.
    // Let's just render them.

    switch (index) {
      case 0:
        return const DeveloperOverviewScreen();
      case 1:
        return const DeveloperUsersScreen();
      case 2:
        return const DeveloperOrdersScreen();
      case 3:
        return const DeveloperCodesScreen();
      case 4:
        return const DeveloperBroadcastsScreen();
      default:
        return const DeveloperOverviewScreen();
    }
  }
}
