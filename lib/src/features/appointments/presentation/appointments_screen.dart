import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dentaltid/src/core/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/shared/widgets/pagination_controls.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  final AppointmentStatus? status;
  const AppointmentsScreen({super.key, this.status});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  SortOption _sortOption = SortOption.dateTimeAsc;
  String _searchQuery = '';
  bool _showUpcomingOnly = false;
  AppointmentStatus? _statusFilter;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.status;
  }

  @override
  Widget build(BuildContext context) {
    final config = AppointmentListConfig(
      query: _searchQuery,
      status: _statusFilter,
      upcomingOnly: _showUpcomingOnly,
      sortOption: _sortOption,
      page: _currentPage,
      pageSize: _pageSize,
    );
    final appointmentsAsyncValue = ref.watch(appointmentsProvider(config));
    final appointmentService = ref.watch(appointmentServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final usage = ref.watch(clinicUsageProvider);
    final userProfile = ref.watch(userProfileProvider).value;
    final isDentist = userProfile?.role == UserRole.dentist;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.appointments),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (!usage.hasReachedAppointmentLimit)
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.primary),
              onPressed: () => context.go('/appointments/add'),
              tooltip: l10n.addAppointment,
            ),
          IconButton(
            icon: Icon(
              _showUpcomingOnly
                  ? LucideIcons.calendar
                  : LucideIcons.calendarDays,
              color: AppColors.primary,
            ),
            onPressed: () => setState(() {
              _showUpcomingOnly = !_showUpcomingOnly;
              _currentPage = 1;
            }),
          ),
          PopupMenuButton<SortOption>(
            icon: const Icon(LucideIcons.arrowUpDown, color: AppColors.primary),
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _currentPage = 1;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortOption.dateTimeAsc,
                child: Text(l10n.timeEarliestFirst),
              ),
              PopupMenuItem(
                value: SortOption.dateTimeDesc,
                child: Text(l10n.timeLatestFirst),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchAppointments,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  _currentPage = 1;
                });
              },
            ),
          ),
          Expanded(
            child: appointmentsAsyncValue.when(
              data: (paginated) {
                final appointments = paginated.appointments;

                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.calendarX,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAppointmentsFound,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          final patientFuture = ref.watch(
                            patientProvider(appointment.patientId),
                          );

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 60,
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(appointment.dateTime),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('a').format(appointment.dateTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(appointment.status),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: InkWell(
                                      onTap: () => context.go(
                                        '/appointments/edit',
                                        extra: appointment,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardTheme.color,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border(
                                            left: BorderSide(
                                              color: _getStatusColor(appointment.status),
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      patientFuture.when(
                                                        data: (p) => Text(
                                                          "${p?.name} ${p?.familyName}",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        loading: () => const Text('...'),
                                                        error: (_, _) => const Text('Error'),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        appointment.createdBy ?? '...',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    _buildStatusBadge(context, appointment.status),
                                                    const SizedBox(width: 4),
                                                    if (appointment.status == AppointmentStatus.waiting) ...[
                                                      IconButton(
                                                        visualDensity: VisualDensity.compact,
                                                        icon: const Icon(LucideIcons.playCircle, color: AppColors.primary, size: 20),
                                                        onPressed: () async {
                                                          if (appointment.id != null) {
                                                            await appointmentService.updateAppointmentStatus(
                                                              appointment.id!,
                                                              AppointmentStatus.inProgress,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        visualDensity: VisualDensity.compact,
                                                        icon: const Icon(LucideIcons.xCircle, color: AppColors.error, size: 20),
                                                        onPressed: () async {
                                                          if (appointment.id != null) {
                                                            await appointmentService.updateAppointmentStatus(
                                                              appointment.id!,
                                                              AppointmentStatus.cancelled,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ] else if (appointment.status == AppointmentStatus.inProgress) ...[
                                                      IconButton(
                                                        visualDensity: VisualDensity.compact,
                                                        icon: const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                                                        onPressed: () async {
                                                          if (appointment.id != null) {
                                                            await appointmentService.updateAppointmentStatus(
                                                              appointment.id!,
                                                              AppointmentStatus.completed,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        visualDensity: VisualDensity.compact,
                                                        icon: const Icon(LucideIcons.xCircle, color: AppColors.error, size: 20),
                                                        onPressed: () async {
                                                          if (appointment.id != null) {
                                                            await appointmentService.updateAppointmentStatus(
                                                              appointment.id!,
                                                              AppointmentStatus.cancelled,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ] else if (appointment.status == AppointmentStatus.completed || appointment.status == AppointmentStatus.cancelled) ...[
                                                      if (isDentist)
                                                        IconButton(
                                                          visualDensity: VisualDensity.compact,
                                                          icon: const Icon(LucideIcons.trash2, color: Colors.grey, size: 20),
                                                          onPressed: () async {
                                                            final confirmed = await showDialog<bool>(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                title: Text(l10n.deleteAppointment),
                                                                content: Text(l10n.confirmDeleteAppointment),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context, false),
                                                                    child: Text(l10n.cancel),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context, true),
                                                                    child: Text(l10n.delete),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirmed == true && appointment.id != null) {
                                                              await appointmentService.deleteAppointment(appointment.id!);
                                                            }
                                                          },
                                                        ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    PaginationControls(
                      currentPage: paginated.currentPage,
                      totalPages: paginated.totalPages,
                      totalItems: paginated.totalCount,
                      onPageChanged: (newPage) {
                        setState(() {
                          _currentPage = newPage;
                        });
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.waiting:
        return AppColors.primary;
      case AppointmentStatus.inProgress:
        return AppColors.warning;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  Widget _buildStatusBadge(BuildContext context, AppointmentStatus status) {
    Color color = _getStatusColor(status);
    String label = '';
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case AppointmentStatus.waiting:
        label = l10n.waiting;
        break;
      case AppointmentStatus.inProgress:
        label = l10n.inProgress;
        break;
      case AppointmentStatus.completed:
        label = l10n.completed;
        break;
      case AppointmentStatus.cancelled:
        label = l10n.cancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
