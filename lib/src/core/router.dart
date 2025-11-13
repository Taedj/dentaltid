import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/cloud_backups_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/settings_screen.dart';
import 'package:dentaltid/src/features/inventory/presentation/inventory_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/add_edit_patient_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/patients_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/dashboard/presentation/home_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/appointments_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/add_edit_appointment_screen.dart';
import 'package:dentaltid/src/shared/widgets/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

final router = GoRouter(
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    final isLoggingIn = state.matchedLocation == '/login';

    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }

    if (isAuthenticated && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/appointments',
          builder: (context, state) {
            if (state.extra is AppointmentStatus) {
              return AppointmentsScreen(
                status: state.extra as AppointmentStatus,
              );
            } else {
              return const AppointmentsScreen();
            }
          },
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditAppointmentScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  AddEditAppointmentScreen(appointment: state.extra as dynamic),
            ),
          ],
        ),
        GoRoute(
          path: '/patients',
          builder: (context, state) {
            // Handle both PatientFilter and null cases
            PatientFilter? filter;
            if (state.extra is PatientFilter) {
              filter = state.extra as PatientFilter;
            }
            return PatientsScreen(filter: filter);
          },
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditPatientScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  AddEditPatientScreen(patient: state.extra as dynamic),
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
