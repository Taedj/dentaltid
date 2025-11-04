import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentService = ref.watch(appointmentServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: FutureBuilder(
        future: appointmentService.getAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments yet.'));
          } else {
            final appointments = snapshot.data!;
            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Patient ID: ${appointment.patientId}'),
                    subtitle: Text(
                        'Date: ${appointment.date.toLocal().toString().split(' ')[0]} Time: ${appointment.time}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        if (appointment.id != null) {
                          await appointmentService
                              .deleteAppointment(appointment.id!);
                          // Refresh the list
                          ref.invalidate(appointmentServiceProvider);
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
          }
        },
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
