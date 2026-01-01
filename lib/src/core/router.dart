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
import 'package:dentaltid/src/features/prescriptions/presentation/advanced_screen.dart';
import 'package:dentaltid/src/shared/widgets/main_layout.dart';
import 'package:dentaltid/src/features/subscription/presentation/subscription_plans_screen.dart';

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

    // --- DEVELOPER & ROLE REDIRECT ---
    if (effectiveLoggedIn) {
      try {
        final settings = SettingsService.instance;
        final roleString = settings.getString('userRole');
        final location = state.matchedLocation;

        if (roleString == 'UserRole.developer') {
          // If developer is active and trying to go to root (dashboard), send to /developer
          if (location == '/') {
            return '/developer';
          }
        } else {
          // Role-based Access Control (RBAC) for Staff
          final isDentist = roleString == 'UserRole.dentist';
          final isReceptionist = roleString == 'UserRole.receptionist';

          // Block /advanced and /finance for anyone NOT a Dentist
          if (!isDentist) {
            if (location.startsWith('/advanced') ||
                location.startsWith('/finance')) {
              return '/';
            }
          }

          // Block /inventory for RECEPTIONIST only
          if (isReceptionist) {
            if (location.startsWith('/inventory')) {
              return '/';
            }
          }
        }
      } catch (_) {}
    }
    // ----------------------------------------

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
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/appointments',
          pageBuilder: (context, state) {
            Widget child;
            if (state.extra is AppointmentStatus) {
              child = AppointmentsScreen(
                status: state.extra as AppointmentStatus,
              );
            } else {
              child = const AppointmentsScreen();
            }
            return NoTransitionPage(key: state.pageKey, child: child);
          },
          routes: [
            GoRoute(
              path: 'add',
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AddEditAppointmentScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
                child: AddEditAppointmentScreen(
                  appointment: state.extra as dynamic,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
          pageBuilder: (context, state) {
            // Handle both PatientFilter and null cases
            PatientFilter? filter;
            if (state.extra is PatientFilter) {
              filter = state.extra as PatientFilter;
            }
            return NoTransitionPage(
              key: state.pageKey,
              child: PatientsScreen(filter: filter),
            );
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const FinanceScreen(),
          ),
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const InventoryScreen(),
          ),
        ),
        GoRoute(
          path: '/advanced',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const AdvancedScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
          routes: [
            GoRoute(
              path: 'cloud-backups',
              builder: (context, state) => const CloudBackupsScreen(),
            ),
            GoRoute(
              path: 'profile',
              builder: (context, state) => const ProfileSettingsScreen(),
            ),
            GoRoute(
              path: 'subscription-plans',
              builder: (context, state) => const SubscriptionPlansScreen(),
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
