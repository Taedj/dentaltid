import 'package:dentaltid/src/features/settings/presentation/cloud_backups_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/settings_screen.dart';
import 'package:dentaltid/src/features/inventory/presentation/inventory_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/add_edit_patient_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/patients_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/dashboard/presentation/home_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/appointments_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/add_edit_appointment_screen.dart';
import 'package:dentaltid/src/shared/widgets/main_layout.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/appointments',
          builder: (context, state) => const AppointmentsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditAppointmentScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => AddEditAppointmentScreen(
                appointment: state.extra as dynamic,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/patients',
          builder: (context, state) => const PatientsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditPatientScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) => AddEditPatientScreen(
                patient: state.extra as dynamic,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'cloud-backups',
              builder: (context, state) => const CloudBackupsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
