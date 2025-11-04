import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/finance/domain/transaction.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsyncValue = ref.watch(patientsProvider(PatientFilter.all));
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: GridView.count(
        crossAxisCount: 3,
        children: [
          _DashboardCard(
            title: 'Patients',
            child: patientsAsyncValue.when(
              data: (patients) => Tooltip(
                message: patients.map((p) => p.name).join('\n'),
                child: Text(patients.length.toString()),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => const Icon(Icons.error),
            ),
          ),
          _DashboardCard(
            title: 'Emergency Patients',
            child: patientsAsyncValue.when(
              data: (patients) => Text(
                patients.where((p) => p.isEmergency).length.toString(),
                style: const TextStyle(color: Colors.red),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => const Icon(Icons.error),
            ),
          ),
          _DashboardCard(
            title: 'Upcoming Appointments',
            child: ref
                .watch(upcomingAppointmentsProvider)
                .when(
                  data: (appointments) => Text(appointments.length.toString()),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => const Icon(Icons.error),
                ),
          ),
          _DashboardCard(
            title: 'Payments',
            child: ref
                .watch(transactionsProvider)
                .when(
                  data: (transactions) {
                    double totalPaid = 0;
                    double totalUnpaid = 0;
                    for (var t in transactions) {
                      if (t.status == TransactionStatus.paid) {
                        totalPaid += t.amount;
                      } else {
                        totalUnpaid += t.amount;
                      }
                    }
                    return Column(
                      children: [
                        Text(
                          'Paid: \$${totalPaid.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          'Unpaid: \$${totalUnpaid.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => const Icon(Icons.error),
                ),
          ),
          _DashboardCard(
            title: 'Quick Actions',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.go('/patients/add'),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.go('/patients'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.go('/settings'),
                ),
              ],
            ),
          ),
          _DashboardCard(
            title: 'Emergency Alerts',
            child: patientsAsyncValue.when(
              data: (patients) {
                final emergencyPatients = patients
                    .where((p) => p.isEmergency)
                    .toList();
                if (emergencyPatients.isEmpty) {
                  return const Text('No emergencies');
                }
                return InkWell(
                  onTap: () {
                    context.go('/patients', extra: PatientFilter.emergency);
                  },
                  child: Container(
                    color: Colors.red.withAlpha(50),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: Text(
                        '${emergencyPatients.length} Emergency Patients',
                      ),
                      subtitle: Text(
                        emergencyPatients.map((p) => p.name).join(', '),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => const Icon(Icons.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
