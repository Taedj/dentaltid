import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum SortOption { dateAsc, dateDesc, timeAsc, timeDesc, patientId }

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  SortOption _sortOption = SortOption.dateDesc;
  String _searchQuery = '';
  bool _showUpcomingOnly = false;

  @override
  Widget build(BuildContext context) {
    final appointmentsAsyncValue = ref.watch(appointmentsProvider);
    final appointmentService = ref.watch(appointmentServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointments),
        actions: [
          IconButton(
            icon: Icon(
              _showUpcomingOnly
                  ? Icons.calendar_today
                  : Icons.calendar_view_week,
            ),
            onPressed: () {
              setState(() {
                _showUpcomingOnly = !_showUpcomingOnly;
              });
            },
            tooltip: _showUpcomingOnly
                ? l10n.showAllAppointments
                : l10n.showUpcomingOnly,
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption option) {
              setState(() {
                _sortOption = option;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              PopupMenuItem<SortOption>(
                value: SortOption.dateDesc,
                child: Text(l10n.dateNewestFirst),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.dateAsc,
                child: Text(l10n.dateOldestFirst),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.timeAsc,
                child: Text(l10n.timeEarliestFirst),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.timeDesc,
                child: Text(l10n.timeLatestFirst),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.patientId,
                child: Text(l10n.patientId),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchAppointments,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: appointmentsAsyncValue.when(
              data: (appointments) {
                // Filter appointments
                var filteredAppointments = appointments.where((appointment) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      appointment.patientId.toString().contains(_searchQuery) ||
                      appointment.date.toString().contains(_searchQuery) ||
                      appointment.time.contains(_searchQuery);

                  final isUpcoming =
                      !_showUpcomingOnly ||
                      appointment.date.isAfter(
                        DateTime.now().subtract(const Duration(days: 1)),
                      );

                  return matchesSearch && isUpcoming;
                }).toList();

                // Sort appointments
                filteredAppointments.sort((a, b) {
                  switch (_sortOption) {
                    case SortOption.dateDesc:
                      return b.date.compareTo(a.date);
                    case SortOption.dateAsc:
                      return a.date.compareTo(b.date);
                    case SortOption.timeAsc:
                      return a.time.compareTo(b.time);
                    case SortOption.timeDesc:
                      return b.time.compareTo(a.time);
                    case SortOption.patientId:
                      return a.patientId.compareTo(b.patientId);
                  }
                });

                if (filteredAppointments.isEmpty) {
                  return Center(child: Text(l10n.noAppointmentsFound));
                }

                return ListView.builder(
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    final isPast = appointment.date.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: isPast ? Colors.grey.withValues(alpha: 0.3) : null,
                      child: ListTile(
                        leading: Icon(
                          isPast ? Icons.history : Icons.calendar_today,
                          color: isPast
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        title: Text(
                          'Patient ID: ${appointment.patientId}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPast ? Colors.grey[700] : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${appointment.date.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: isPast ? Colors.grey[600] : null,
                              ),
                            ),
                            Text(
                              'Time: ${appointment.time}',
                              style: TextStyle(
                                color: isPast ? Colors.grey[600] : null,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPast)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.deleteAppointment),
                                    content: Text(
                                      l10n.confirmDeleteAppointment,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: Text(l10n.deleteAppointment),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true &&
                                    appointment.id != null) {
                                  await appointmentService.deleteAppointment(
                                    appointment.id!,
                                  );
                                  ref.invalidate(appointmentsProvider);
                                }
                              },
                            ),
                          ],
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
          ),
        ],
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
