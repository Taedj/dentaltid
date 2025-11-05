import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/currency_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double cardHeight = constraints.maxHeight / 2;
          double cardWidth = constraints.maxWidth / 3;
          return Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Patients',
                      icon: Icons.people,
                      gradientColors: [
                        Colors.blue.shade300,
                        Colors.blue.shade700,
                      ],
                      child: patientsAsyncValue.when(
                        data: (patients) => Tooltip(
                          message: "Total number of patients",
                          child: Text(
                            patients.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        error: (e, s) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Emergency Patients',
                      icon: Icons.local_hospital,
                      gradientColors: [
                        Colors.red.shade300,
                        Colors.red.shade700,
                      ],
                      child: patientsAsyncValue.when(
                        data: (patients) => Text(
                          patients
                              .where((p) => p.isEmergency)
                              .length
                              .toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        error: (e, s) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Upcoming Appointments',
                      icon: Icons.calendar_today,
                      gradientColors: [
                        Colors.green.shade300,
                        Colors.green.shade700,
                      ],
                      child: ref
                          .watch(upcomingAppointmentsProvider)
                          .when(
                            data: (appointments) => Text(
                              appointments.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            error: (e, s) =>
                                const Icon(Icons.error, color: Colors.white),
                          ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Payments',
                      icon: Icons.attach_money,
                      gradientColors: [
                        Colors.purple.shade300,
                        Colors.purple.shade700,
                      ],
                      child: ref
                          .watch(transactionsProvider)
                          .when(
                            data: (transactions) {
                              double totalPaid = 0;
                              double totalUnpaid = 0;
                              for (var t in transactions) {
                                totalPaid += t.paidAmount;
                                totalUnpaid += (t.totalAmount - t.paidAmount);
                              }
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Paid: $currency${totalPaid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Unpaid: $currency${totalUnpaid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                            error: (e, s) =>
                                const Icon(Icons.error, color: Colors.white),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Quick Actions',
                      icon: Icons.touch_app,
                      gradientColors: [
                        Colors.orange.shade300,
                        Colors.orange.shade700,
                      ],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () => context.go('/patients/add'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () => context.go('/patients'),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () => context.go('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: _DashboardCard(
                      title: 'Emergency Alerts',
                      icon: Icons.error_outline,
                      gradientColors: [
                        Colors.red.shade300,
                        Colors.red.shade700,
                      ],
                      child: patientsAsyncValue.when(
                        data: (patients) {
                          final emergencyPatients = patients
                              .where((p) => p.isEmergency)
                              .toList();
                          if (emergencyPatients.isEmpty) {
                            return const Text(
                              'No emergencies',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            );
                          }
                          return InkWell(
                            onTap: () {
                              context.go(
                                '/patients',
                                extra: PatientFilter.emergency,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                Text(
                                  '${emergencyPatients.length} Emergency Patients',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  emergencyPatients
                                      .map((p) => p.name)
                                      .take(2)
                                      .join(', '),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        error: (e, s) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.child,
  });

  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
