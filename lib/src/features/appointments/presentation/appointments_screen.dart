import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum SortOption { dateTimeAsc, dateTimeDesc, patientId } // Updated enum

class AppointmentsScreen extends ConsumerStatefulWidget {
  final AppointmentStatus? status;
  const AppointmentsScreen({super.key, this.status});

  String _getLocalizedStatus(BuildContext context, AppointmentStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case AppointmentStatus.waiting:
        return l10n.waiting;
      case AppointmentStatus.inProgress:
        return l10n.inProgress;
      case AppointmentStatus.completed:
        return l10n.completed;
      case AppointmentStatus.cancelled:
        return l10n.cancelled;
    }
  }

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  SortOption _sortOption = SortOption.dateTimeDesc; // Updated default sort
  String _searchQuery = '';
  bool _showUpcomingOnly = false;
  AppointmentStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsyncValue = ref.watch(appointmentsProvider);
    final appointmentService = ref.watch(appointmentServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointments),
        actions: [
          if (_statusFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                });
              },
              tooltip: 'Clear filter',
            ),
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
                value: SortOption.dateTimeDesc,
                child: Text(l10n.dateNewestFirst),
              ),
              PopupMenuItem<SortOption>(
                value: SortOption.dateTimeAsc,
                child: Text(l10n.dateOldestFirst),
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
                ).colorScheme.surfaceContainerHighest.withAlpha(77),
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
                      appointment.dateTime.toLocal().toString().contains(
                        _searchQuery,
                      ); // Use dateTime

                  final isUpcoming =
                      !_showUpcomingOnly ||
                      (appointment.status != AppointmentStatus.completed &&
                          appointment.status != AppointmentStatus.cancelled);

                  final statusMatch =
                      _statusFilter == null ||
                      appointment.status == _statusFilter;

                  return matchesSearch && isUpcoming && statusMatch;
                }).toList();

                // Sort appointments
                filteredAppointments.sort((a, b) {
                  switch (_sortOption) {
                    case SortOption.dateTimeDesc: // Updated sort option
                      return b.dateTime.compareTo(a.dateTime);
                    case SortOption.dateTimeAsc: // Updated sort option
                      return a.dateTime.compareTo(b.dateTime);
                    case SortOption.patientId:
                      return a.patientId.compareTo(b.patientId);
                  }
                });

                if (filteredAppointments.isEmpty) {
                  return Center(child: Text(l10n.noAppointmentsFound));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    final patientFuture = ref.watch(
                      patientProvider(appointment.patientId),
                    );

                    Color cardColor;
                    IconData leadingIcon;
                    Color iconColor;
                    Color statusColor;

                    switch (appointment.status) {
                      case AppointmentStatus.waiting:
                        cardColor = Theme.of(context).colorScheme.surface;
                        leadingIcon = Icons.hourglass_empty;
                        iconColor = Theme.of(context).colorScheme.primary;
                        statusColor = Colors.blue;
                        break;
                      case AppointmentStatus.inProgress:
                        cardColor = Theme.of(context).colorScheme.surface;
                        leadingIcon = Icons.play_circle_fill;
                        iconColor = Theme.of(context).colorScheme.secondary;
                        statusColor = Colors.orange;
                        break;
                      case AppointmentStatus.completed:
                        cardColor = Theme.of(
                          context,
                        ).colorScheme.surface.withAlpha(128);
                        leadingIcon = Icons.check_circle;
                        iconColor = Colors.green;
                        statusColor = Colors.green;
                        break;
                      case AppointmentStatus.cancelled:
                        cardColor = Theme.of(
                          context,
                        ).colorScheme.surface.withAlpha(128);
                        leadingIcon = Icons.cancel;
                        iconColor = Theme.of(context).colorScheme.error;
                        statusColor = Colors.red;
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: statusColor.withAlpha(128),
                          width: 1,
                        ),
                      ),
                      color: cardColor,
                      child: ListTile(
                        leading: Icon(leadingIcon, color: iconColor, size: 32),
                        title: patientFuture.when(
                          data: (patient) => Text(
                            patient?.name ?? l10n.unknownPatient,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          loading: () => Text(l10n.loading),
                          error: (err, stack) => Text(l10n.errorLabel),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.date}: ${appointment.dateTime.toLocal().toIso8601String().split('T')[0]}', // Display date part
                            ),
                            Text(
                              '${l10n.timeHHMM}: ${appointment.dateTime.toLocal().toIso8601String().split('T')[1].substring(0, 5)}', // Display time part
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                widget._getLocalizedStatus(
                                  context,
                                  appointment.status,
                                ),
                              ),
                              backgroundColor: statusColor.withAlpha(51),
                              labelStyle: TextStyle(color: statusColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (appointment.status == AppointmentStatus.waiting)
                              IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  if (appointment.id != null) {
                                    await appointmentService
                                        .updateAppointmentStatus(
                                          appointment.id!,
                                          AppointmentStatus.inProgress,
                                        );
                                    ref.invalidate(appointmentsProvider);
                                    ref.invalidate(todaysAppointmentsProvider);
                                    ref.invalidate(
                                      todaysEmergencyAppointmentsProvider,
                                    );
                                  }
                                },
                                tooltip: l10n.startAppointment,
                              ),
                            if (appointment.status ==
                                AppointmentStatus.inProgress)
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  if (appointment.id != null) {
                                    await appointmentService
                                        .updateAppointmentStatus(
                                          appointment.id!,
                                          AppointmentStatus.completed,
                                        );
                                    ref.invalidate(appointmentsProvider);
                                    ref.invalidate(todaysAppointmentsProvider);
                                    ref.invalidate(
                                      todaysEmergencyAppointmentsProvider,
                                    );
                                  }
                                },
                                tooltip: l10n.completeAppointment,
                              ),
                            if (appointment.status !=
                                    AppointmentStatus.completed &&
                                appointment.status !=
                                    AppointmentStatus.cancelled)
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.cancelAppointment),
                                      content: Text(
                                        l10n.confirmCancelAppointment,
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
                                          child: Text(l10n.confirm),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true &&
                                      appointment.id != null) {
                                    await appointmentService
                                        .updateAppointmentStatus(
                                          appointment.id!,
                                          AppointmentStatus.cancelled,
                                        );
                                    ref.invalidate(appointmentsProvider);
                                    ref.invalidate(todaysAppointmentsProvider);
                                    ref.invalidate(
                                      todaysEmergencyAppointmentsProvider,
                                    );
                                  }
                                },
                                tooltip: l10n.cancelAppointment,
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
                                        child: Text(
                                          l10n.confirm,
                                        ), // Use l10n.confirm
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
                                  ref.invalidate(todaysAppointmentsProvider);
                                  ref.invalidate(
                                    todaysEmergencyAppointmentsProvider,
                                  );
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
