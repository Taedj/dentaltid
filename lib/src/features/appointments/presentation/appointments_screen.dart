import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

enum SortOption { dateTimeAsc, dateTimeDesc, patientId }

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
  SortOption _sortOption = SortOption.dateTimeDesc;
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

    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.appointments),
            if (userProfile != null && !userProfile.isPremium)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      '${userProfile.cumulativeAppointments}/100',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ),
              ),
          ],
        ),
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
            tooltip: _showUpcomingOnly ? l10n.showAllAppointments : l10n.showUpcomingOnly,
          ),
          PopupMenuButton<SortOption>(
            onSelected: (option) {
              setState(() {
                _sortOption = option;
              });
            },
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.dateTimeAsc,
                child: Text(l10n.timeEarliestFirst),
              ),
              PopupMenuItem(
                value: SortOption.dateTimeDesc,
                child: Text(l10n.timeLatestFirst),
              ),
              PopupMenuItem(
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
                var filteredAppointments = appointments.where((appointment) {
                  final matchesSearch = appointment.patientId
                      .toString()
                      .contains(_searchQuery);
                  final isUpcoming = !_showUpcomingOnly ||
                      appointment.dateTime.isAfter(DateTime.now());
                  final statusMatch = _statusFilter == null || 
                                     appointment.status == _statusFilter;
                  
                  return matchesSearch && isUpcoming && statusMatch;
                }).toList();

                // Sort
                switch (_sortOption) {
                  case SortOption.dateTimeAsc:
                    filteredAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                    break;
                  case SortOption.dateTimeDesc:
                    filteredAppointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    break;
                  case SortOption.patientId:
                    filteredAppointments.sort((a, b) => a.patientId.compareTo(b.patientId));
                    break;
                }

                if (filteredAppointments.isEmpty) {
                  return Center(child: Text(l10n.noAppointmentsFound));
                }

                return ListView.builder(
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
                              '${l10n.dateLabel}: ${appointment.dateTime.toLocal().toIso8601String().split('T')[0]}',
                            ),
                            Text(
                              '${l10n.timeHHMM}: ${appointment.dateTime.toLocal().toIso8601String().split('T')[1].substring(0, 5)}',
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
                                      content: Text(l10n.confirmCancelAppointment),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(l10n.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(l10n.confirm),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && appointment.id != null) {
                                    await appointmentService.updateAppointmentStatus(
                                      appointment.id!,
                                      AppointmentStatus.cancelled,
                                    );
                                    ref.invalidate(appointmentsProvider);
                                    ref.invalidate(todaysAppointmentsProvider);
                                    ref.invalidate(todaysEmergencyAppointmentsProvider);
                                  }
                                },
                                tooltip: l10n.cancelAppointment,
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
              error: (err, stack) => Center(child: Text('Error: $err')),
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