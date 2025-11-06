import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/core/currency_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          StreamBuilder<DateTime>(
            stream: Stream.periodic(
              const Duration(seconds: 1),
              (_) => DateTime.now(),
            ),
            builder: (context, snapshot) {
              final currentTime = snapshot.data ?? DateTime.now();
              return Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeDr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 32),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(currentTime),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 32),
                    Text(
                      DateFormat('HH:mm:ss').format(currentTime),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: LayoutBuilder(
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
                            title: l10n.patients,
                            icon: Icons.people,
                            gradientColors: [
                              Colors.blue.shade300,
                              Colors.blue.shade700,
                            ],
                            child: patientsAsyncValue.when(
                              data: (patients) => Tooltip(
                                message: l10n.totalNumberOfPatients,
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
                            title: l10n.emergencyPatients,
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
                            title: l10n.todaysAppointmentsFlow,
                            icon: Icons.access_time,
                            gradientColors: [
                              Colors.teal.shade300,
                              Colors.teal.shade700,
                            ],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAppointmentStatusText(
                                  context,
                                  l10n.waiting,
                                  ref.watch(waitingAppointmentsProvider),
                                  AppointmentStatus.waiting,
                                ),
                                _buildAppointmentStatusText(
                                  context,
                                  l10n.inProgress,
                                  ref.watch(inProgressAppointmentsProvider),
                                  AppointmentStatus.inProgress,
                                ),
                                _buildAppointmentStatusText(
                                  context,
                                  l10n.completed,
                                  ref.watch(completedAppointmentsProvider),
                                  AppointmentStatus.completed,
                                ),
                              ],
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
                            title: l10n.payments,
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
                                      totalUnpaid +=
                                          (t.totalAmount - t.paidAmount);
                                    }
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${l10n.paid} $currency${totalPaid.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${l10n.unpaid} $currency${totalUnpaid.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                  error: (e, s) => const Icon(
                                    Icons.error,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _DashboardCard(
                            title: l10n.emergencyAlerts,
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
                                  return Text(
                                    l10n.noEmergencies,
                                    style: const TextStyle(
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
                                        '${emergencyPatients.length} ${l10n.emergencyPatients}',
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusText(
    BuildContext context,
    String title,
    AsyncValue<List<Appointment>> appointmentsAsyncValue,
    AppointmentStatus status,
  ) {
    return appointmentsAsyncValue.when(
      data: (appointments) => InkWell(
        onTap: () {
          // Navigate to appointments screen with filter
          context.go('/appointments', extra: status);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '$title: ${appointments.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white,
        ),
      ),
      error: (e, s) => const Icon(Icons.error, color: Colors.white),
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
