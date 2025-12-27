import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/settings/presentation/profile_settings_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_overview_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_users_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_codes_screen.dart';
import 'package:dentaltid/src/features/developer/presentation/developer_broadcasts_screen.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/cloud_backups_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/settings_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/staff_settings_screen.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
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
    final isLoggingIn = state.matchedLocation == '/login';

    // Check both Firebase Auth and Persistent Storage
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // If not logged in via Firebase, check if we have a valid "Remember Me" session or a Staff login
    bool hasRememberMe = false;
    bool isStaffLoggedIn = false;
    if (!isLoggedIn) {
      try {
        final settings = SettingsService.instance;
        hasRememberMe =
            (settings.getBool('remember_me') ?? false) &&
            (settings.getString('cached_user_profile') != null);

        isStaffLoggedIn = settings.getString('managedUserProfile') != null;
      } catch (_) {}
    }

    final effectiveLoggedIn = isLoggedIn || hasRememberMe || isStaffLoggedIn;

    if (!effectiveLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // --- DEVELOPER REDIRECT ---
    if (effectiveLoggedIn) {
      try {
        final settings = SettingsService.instance;
        final roleString = settings.getString('userRole');

        if (roleString == 'UserRole.developer') {
          // If developer is active and trying to go to root (dashboard), send to /developer
          if (state.matchedLocation == '/') {
            return '/developer';
          }
          // Allow access to /developer/* and /settings/* but maybe block others?
          // For now, soft redirect is enough.
        }
      } catch (_) {}
    }
    // --------------------------

    if (effectiveLoggedIn && isLoggingIn) {
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
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AddEditAppointmentScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                opaque: false,
                barrierColor: Colors.black.withValues(alpha: 0.1),
              ),
            ),
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: AddEditAppointmentScreen(appointment: state.extra as dynamic),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                opaque: false,
                barrierColor: Colors.black.withValues(alpha: 0.1),
              ),
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
              path: 'edit-transaction',
              builder: (context, state) =>
                  AddTransactionScreen(transaction: state.extra as dynamic),
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
        GoRoute(
          path: '/staff-settings',
          builder: (context, state) => const StaffSettingsScreen(),
        ),
        GoRoute(
          path: '/developer',
          builder: (context, state) => const DeveloperOverviewScreen(),
          routes: [
            GoRoute(
              path: 'users',
              builder: (context, state) => const DeveloperUsersScreen(),
            ),
            GoRoute(
              path: 'codes',
              builder: (context, state) => const DeveloperCodesScreen(),
            ),
            GoRoute(
              path: 'broadcasts',
              builder: (context, state) => const DeveloperBroadcastsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
