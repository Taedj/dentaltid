import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsyncValue = ref.watch(appointmentsProvider);
    final appointmentService = ref.watch(appointmentServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: appointmentsAsyncValue.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments yet.'));
          }
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Patient ID: ${appointment.patientId}'),
                  subtitle: Text(
                    'Date: ${appointment.date.toLocal().toString().split(' ')[0]} Time: ${appointment.time}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Appointment'),
                          content: const Text(
                            'Are you sure you want to delete this appointment?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && appointment.id != null) {
                        await appointmentService.deleteAppointment(
                          appointment.id!,
                        );
                        ref.invalidate(
                          appointmentsProvider,
                        ); // Invalidate to refresh
                      }
                    },
                  ),
                  onTap: () {
                    context.go('/appointments/edit', extra: appointment);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/appointments/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
