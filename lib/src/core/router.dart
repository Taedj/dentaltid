import 'package:dentaltid/src/features/settings/presentation/profile_settings_screen.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/cloud_backups_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/settings_screen.dart';
import 'package:dentaltid/src/features/inventory/presentation/inventory_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/finance_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/recurring_charges_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/add_edit_recurring_charge_screen.dart';
import 'package:dentaltid/src/features/finance/presentation/add_transaction_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/add_edit_patient_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/patients_screen.dart';
import 'package:dentaltid/src/features/patients/presentation/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/dashboard/presentation/home_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/appointments_screen.dart';
import 'package:dentaltid/src/features/appointments/presentation/add_edit_appointment_screen.dart';
import 'package:dentaltid/src/shared/widgets/main_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';

final router = GoRouter(
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.matchedLocation == '/login';

    // Temporarily deactivate login redirect
    // if (user == null && !isLoggingIn) {
    //   return '/login';
    // }

    if (user != null && isLoggingIn) {
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
            GoRoute(
              path: 'profile',
              builder: (context, state) =>
                  PatientProfileScreen(patient: state.extra as Patient),
            ),
          ],
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
          routes: [
            GoRoute(
              path: 'add-transaction',
              builder: (context, state) => const AddTransactionScreen(),
            ),
            GoRoute(
              path: 'recurring-charges',
              builder: (context, state) => const RecurringChargesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) =>
                      const AddEditRecurringChargeScreen(),
                ),
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => AddEditRecurringChargeScreen(
                    recurringCharge: state.extra as dynamic,
                  ),
                ),
              ],
            ),
          ],
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
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileSettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
