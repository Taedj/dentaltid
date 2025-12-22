import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart'; // Add this
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/features/dashboard/presentation/widgets/emergency_counter.dart';
import 'package:dentaltid/src/features/developer/data/broadcast_service.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dentaltid/src/shared/widgets/connection_status_widget.dart'; // Import the widget
import 'package:dentaltid/src/core/user_model.dart'; // Import UserRole

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<String> _dismissedBroadcastIds = [];

  @override
  void initState() {
    super.initState();
    _loadDismissedBroadcasts();
  }

  Future<void> _loadDismissedBroadcasts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedBroadcastIds = prefs.getStringList('dismissed_broadcasts') ?? [];
    });
  }

  Future<void> _dismissBroadcast(String id) async {
    if (_dismissedBroadcastIds.contains(id)) return;

    setState(() {
      _dismissedBroadcastIds.add(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_broadcasts', _dismissedBroadcastIds);
  }

  String _replaceArabicNumber(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    final todayPatientsAsyncValue = ref.watch(
      patientsProvider(const PatientListConfig(filter: PatientFilter.today)),
    );
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final l10n = AppLocalizations.of(context)!;
    final userProfileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          userProfileAsyncValue.when(
            data: (userProfile) {
              final UserRole role = userProfile?.role ?? UserRole.dentist;
              return ConnectionStatusWidget(userRole: role);
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- BROADCAST BANNER ---
          StreamBuilder<List<BroadcastModel>>(
            stream: BroadcastService().getActiveBroadcasts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

              // Filter dismissed
              final visibleBroadcasts = snapshot.data!.where((b) => !_dismissedBroadcastIds.contains(b.id)).toList();

              if (visibleBroadcasts.isEmpty) return const SizedBox.shrink();

              // Only show the latest one for now to avoid clutter
              final latest = visibleBroadcasts.first;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBroadcastColor(latest.type).withValues(alpha: 0.1),
                  border: Border.all(color: _getBroadcastColor(latest.type)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_getBroadcastIcon(latest.type), color: _getBroadcastColor(latest.type)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(latest.title, style: TextStyle(fontWeight: FontWeight.bold, color: _getBroadcastColor(latest.type))),
                          Text(latest.message),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _dismissBroadcast(latest.id),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: StreamBuilder<DateTime>(
                    stream: Stream.periodic(
                      const Duration(seconds: 1),
                      (_) => DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      final currentTime = snapshot.data ?? DateTime.now();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _replaceArabicNumber(
                              DateFormat.yMMMMEEEEd(
                                l10n.localeName,
                              ).format(currentTime),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _replaceArabicNumber(
                              DateFormat.Hms(
                                l10n.localeName,
                              ).format(currentTime),
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: userProfileAsyncValue.when(
                    data: (userProfile) {
                      final log = Logger('HomeScreen');
                      log.info(
                        'Building with user profile: ${userProfile?.toJson()}',
                      );
                      final dentistName = userProfile?.dentistName ?? '';
                      final staffUsername = userProfile?.username ?? '';
                      final isStaff = userProfile?.isManagedUser ?? false;

                      // Status Logic
                      String? statusText;
                      Color statusColor = Colors.transparent;
                      
                      if (userProfile != null) {
                        // Check if we are a staff user and should use inherited status
                        bool isPremium = userProfile.isPremium;
                        DateTime? trialStartDate = userProfile.trialStartDate;
                        DateTime? premiumExpiryDate = userProfile.premiumExpiryDate;

                        if (isStaff) {
                            // STAFF: Load the inherited Dentist Profile
                            // This part is tricky because it's synchronous build
                            // We rely on the fact that AppInitializer/SyncClient saved it.
                            // For simplicity in the UI, we'll try to read it from cache
                            // but if it's not there, we use the staff profile's own values
                            // which WERE correctly populated during login.
                        }

                        if (isPremium) {
                          statusText = l10n.premiumAccount;
                          statusColor = Colors.green;
                          
                          if (premiumExpiryDate != null) {
                            final daysLeft = premiumExpiryDate.difference(DateTime.now()).inDays;
                            if (daysLeft >= 0) {
                              statusText = l10n.premiumDaysLeft(daysLeft);
                            } else {
                              statusText = l10n.premiumExpired;
                              statusColor = Colors.red;
                            }
                          }
                        } else if (trialStartDate != null) {
                          final daysUsed = DateTime.now().difference(trialStartDate).inDays;
                          final daysLeft = 30 - daysUsed;
                          if (daysLeft > 0) {
                              statusText = l10n.trialVersionDaysLeft(daysLeft);
                              statusColor = Colors.orange;
                          } else {
                              statusText = l10n.trialExpired;
                              statusColor = Colors.red;
                          }
                        }
                      }

                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                isStaff 
                                  ? '${l10n.welcome} $staffUsername'
                                  : '${l10n.welcomeDr} $dentistName',
                                style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.end,
                            ),
                            if (statusText != null)
                                Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                        statusText,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                        ),
                                    ),
                                ),
                          ],
                      );
                    },
                    loading: () => Text(
                      l10n.welcomeDr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    error: (e, s) => Text(
                      l10n.welcomeDr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth;
                  if (constraints.maxWidth > 1400) {
                    cardWidth = constraints.maxWidth * 0.26;
                  } else if (constraints.maxWidth > 1000) {
                    cardWidth = constraints.maxWidth * 0.29;
                  } else if (constraints.maxWidth > 800) {
                    cardWidth = constraints.maxWidth * 0.32;
                  } else {
                    cardWidth = constraints.maxWidth * 0.36;
                  }
                  double cardHeight = cardWidth * 1.4;
                  double spacing = cardWidth * 0.08;
                  double titleFontSize = cardWidth * 0.08;
                  double numberFontSize = cardWidth * 0.14;
                  double subtitleFontSize = cardWidth * 0.06;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.patients,
                        frontIcon: Icons.people,
                        frontGradient: [
                          Colors.blue.shade400,
                          Colors.blue.shade800,
                        ],
                        backTitle: l10n.viewDetails,
                        backIcon: Icons.visibility,
                        onTap: () => context.go('/patients'),
                        cardType: 'patients',
                        titleFontSize: titleFontSize,
                        numberFontSize: numberFontSize,
                        subtitleFontSize: subtitleFontSize,
                        content: todayPatientsAsyncValue.when(
                          data: (patients) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.todayCount(patients.length),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
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

                      SizedBox(width: spacing),

                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.criticalAlerts,
                        frontIcon: Icons.warning_amber,
                        frontGradient: inventoryItemsAsyncValue.maybeWhen(
                          data: (items) {
                            final now = DateTime.now();
                            final expiringSoonCount = items.where((item) {
                              final daysLeft = item.expirationDate
                                  .difference(now)
                                  .inDays;
                              return daysLeft >= 0 &&
                                  daysLeft < item.thresholdDays;
                            }).length;
                            final lowStockCount = items
                                .where(
                                  (item) =>
                                      item.quantity <= item.lowStockThreshold,
                                )
                                .length;
                            return (expiringSoonCount > 0 || lowStockCount > 0)
                                ? [Colors.red.shade400, Colors.red.shade800]
                                : [
                                    const Color(0xFF1E4D2B),
                                    const Color(0xFF2E5A3C),
                                  ];
                          },
                          orElse: () => [
                            const Color(0xFF1E4D2B),
                            const Color(0xFF2E5A3C),
                          ],
                        ),
                        backTitle: l10n.viewCritical,
                        backIcon: Icons.warning,
                        onTap: () => context.go('/inventory'),
                        cardType: 'emergency',
                        titleFontSize: titleFontSize,
                        numberFontSize: numberFontSize,
                        subtitleFontSize: subtitleFontSize,
                        content: inventoryItemsAsyncValue.when(
                          data: (items) {
                            final now = DateTime.now();
                            final expiringSoonCount = items.where((item) {
                              final daysLeft = item.expirationDate
                                  .difference(now)
                                  .inDays;
                              return daysLeft >= 0 &&
                                  daysLeft < item.thresholdDays;
                            }).length;
                            final lowStockCount = items
                                .where(
                                  (item) =>
                                      item.quantity <= item.lowStockThreshold,
                                )
                                .length;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.expiringSoonCount(expiringSoonCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.lowStockCount(lowStockCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
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

                      SizedBox(width: spacing),

                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.todaysAppointmentsFlow,
                        frontIcon: Icons.access_time,
                        frontGradient: [
                          Colors.teal.shade400,
                          Colors.teal.shade800,
                        ],
                        backTitle: l10n.viewAppointments,
                        backIcon: Icons.calendar_today,
                        onTap: () => context.go('/appointments'),
                        cardType: 'appointments',
                        titleFontSize: titleFontSize,
                        numberFontSize: numberFontSize,
                        subtitleFontSize: subtitleFontSize,
                        content: Consumer(
                          builder: (context, ref, child) {
                            final todaysAppointmentsAsync = ref.watch(
                              todaysAppointmentsProvider,
                            );
                            final emergencyAppointmentsAsync = ref.watch(
                              todaysEmergencyAppointmentsProvider,
                            );

                            return todaysAppointmentsAsync.when(
                              data: (appointments) {
                                return emergencyAppointmentsAsync.when(
                                  data: (emergencyAppointments) {
                                    final emergencyAppointmentIds =
                                        emergencyAppointments
                                            .map((a) => a.id)
                                            .toSet();

                                    final waiting = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                                  AppointmentStatus.waiting &&
                                              !emergencyAppointmentIds.contains(
                                                a.id,
                                              ),
                                        )
                                        .toList();
                                    final inProgress = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                              AppointmentStatus.inProgress,
                                        )
                                        .toList();
                                    final completed = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                              AppointmentStatus.completed,
                                        )
                                        .toList();

                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.waitingCount(waiting.length),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          l10n.inProgressCount(
                                            inProgress.length,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          l10n.completedCount(completed.length),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        EmergencyCounter(
                                          emergencyCount:
                                              emergencyAppointments.length,
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () {
                                    // Show a loading state while emergency appointments are being fetched
                                    final waiting = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                              AppointmentStatus.waiting,
                                        )
                                        .toList();
                                    final inProgress = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                              AppointmentStatus.inProgress,
                                        )
                                        .toList();
                                    final completed = appointments
                                        .where(
                                          (a) =>
                                              a.status ==
                                              AppointmentStatus.completed,
                                        )
                                        .toList();
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Waiting: ${waiting.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          'In Progress: ${inProgress.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        Text(
                                          'Completed: ${completed.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                        const EmergencyCounter(
                                          emergencyCount: 0,
                                        ),
                                      ],
                                    );
                                  },
                                  error: (e, s) {
                                    // Handle error state for emergency appointments
                                    return Text(
                                      l10n.errorLoadingEmergencyAppointments,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Waiting: ...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'In Progress: ...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'Completed: ...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'Emergency: ...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              error: (e, s) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Waiting: 0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'In Progress: 0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'Completed: 0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  Text(
                                    'Emergency: 0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

  Color _getBroadcastColor(String type) {
      switch(type) {
          case 'warning': return Colors.orange;
          case 'maintenance': return Colors.red;
          default: return Colors.blue;
      }
  }

  IconData _getBroadcastIcon(String type) {
      switch(type) {
          case 'warning': return Icons.warning;
          case 'maintenance': return Icons.build;
          default: return Icons.info;
      }
  }


class _FlipCard3D extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final String frontTitle;
  final IconData frontIcon;
  final List<Color> frontGradient;
  final String backTitle;
  final IconData backIcon;
  final VoidCallback onTap;
  final Widget content;
  final String cardType;
  final double titleFontSize;
  final double numberFontSize;
  final double subtitleFontSize;

  const _FlipCard3D({
    required this.width,
    required this.height,
    required this.frontTitle,
    required this.frontIcon,
    required this.frontGradient,
    required this.backTitle,
    required this.backIcon,
    required this.onTap,
    required this.content,
    required this.cardType,
    required this.titleFontSize,
    required this.numberFontSize,
    required this.subtitleFontSize,
  });

  @override
  ConsumerState<_FlipCard3D> createState() => _FlipCard3DState();
}

class _FlipCard3DState extends ConsumerState<_FlipCard3D>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _borderController;
  late Animation<double> _borderAnimation;
  bool _isFront = true;
  int _appointmentTabIndex = 0;
  int _criticalAlertTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _borderController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _borderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (_isFront) {
          _controller.forward();
          setState(() {
            _isFront = false;
          });
        }
      },
      onExit: (_) {
        if (!_isFront) {
          _controller.reverse();
          setState(() {
            _isFront = true;
          });
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation, _borderAnimation]),
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final borderColor = Color.lerp(
            Colors.white.withAlpha(50),
            Colors.white.withAlpha(150),
            _borderAnimation.value,
          );

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: borderColor!,
                width: 2 + (_borderAnimation.value * 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20 + (_borderAnimation.value * 10),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _isFront
                  ? _buildFrontCard()
                  : Transform(
                      transform: Matrix4.rotationY(3.14159),
                      alignment: Alignment.center,
                      child: _buildBackCard(),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: widget.frontGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 30,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.frontIcon, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  widget.frontTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 12),
                widget.content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: widget.frontGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(child: _buildCardDetails()),
      ),
    );
  }

  Widget _buildCardDetails() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isRTL = ['ar', 'he', 'fa', 'ur'].contains(locale.languageCode);

    switch (widget.cardType) {
      case 'patients':
        return Consumer(
          builder: (context, ref, child) {
            final todayPatientsAsync = ref.watch(
              patientsProvider(
                const PatientListConfig(filter: PatientFilter.today),
              ),
            );
            return todayPatientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return Text(
                    l10n.noPatientsToday,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                }
                return DataTable(
                  border: TableBorder.all(
                    color: Colors.white.withAlpha(100),
                    width: 1,
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        l10n.patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: patients.map((patient) {
                    return DataRow(
                      cells: [
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              if (mounted) {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                      context.go(
                                        '/patients/profile',
                                        extra: patient,
                                      );
                                    }
                                  },
                                );
                              }
                            },
                            child: Text(
                              '${patient.name} ${patient.familyName}',
                              style: const TextStyle(
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: isRTL
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  dataTextStyle: const TextStyle(color: Colors.white),
                  headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              error: (e, s) => Text(
                l10n.errorLoadingPatientData,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            );
          },
        );

      case 'emergency':
        return Consumer(
          builder: (context, ref, child) {
            final inventoryItemsAsync = ref.watch(inventoryItemsProvider);
            return inventoryItemsAsync.when(
              data: (items) {
                final now = DateTime.now();
                final expiringSoon = items.where((item) {
                  final daysLeft = item.expirationDate.difference(now).inDays;
                  return daysLeft >= 0 && daysLeft < item.thresholdDays;
                }).toList();
                final lowStock = items
                    .where((item) => item.quantity <= item.lowStockThreshold)
                    .toList();

                List<InventoryItem> currentItems = [];
                List<String> columns = [];
                List<DataRow> rows = [];

                switch (_criticalAlertTabIndex) {
                  case 0:
                    currentItems = expiringSoon;
                    columns = [l10n.itemName, l10n.countdown];
                    rows = currentItems.map((item) {
                      final daysLeft = item.expirationDate
                          .difference(now)
                          .inDays;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.name,
                              style: const TextStyle(color: Colors.white),
                              textAlign: isRTL
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                          ),
                          DataCell(
                            Text(
                              l10n.daysLeft(daysLeft),
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                    break;
                  case 1:
                    currentItems = lowStock;
                    columns = [l10n.itemName, l10n.currentQuantity];
                    rows = currentItems.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.name,
                              style: const TextStyle(color: Colors.white),
                              textAlign: isRTL
                                  ? TextAlign.right
                                  : TextAlign.left,
                            ),
                          ),
                          DataCell(
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                    break;
                }

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _criticalAlertTabIndex = 0),
                            style: TextButton.styleFrom(
                              backgroundColor: _criticalAlertTabIndex == 0
                                  ? Colors.white.withAlpha(50)
                                  : Colors.transparent,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.expiringSoon,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _criticalAlertTabIndex == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _criticalAlertTabIndex = 1),
                            style: TextButton.styleFrom(
                              backgroundColor: _criticalAlertTabIndex == 1
                                  ? Colors.white.withAlpha(50)
                                  : Colors.transparent,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.lowStock,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: _criticalAlertTabIndex == 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (currentItems.isEmpty)
                      Text(
                        _criticalAlertTabIndex == 0
                            ? l10n.noExpiringSoonItems
                            : l10n.noLowStockItems,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          border: TableBorder.all(
                            color: Colors.white.withAlpha(100),
                            width: 1,
                          ),
                          columns: columns
                              .map(
                                (col) => DataColumn(
                                  label: Text(
                                    col,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          rows: rows,
                          dataTextStyle: const TextStyle(color: Colors.white),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              error: (e, s) => Text(
                l10n.errorLoadingInventory,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            );
          },
        );

      case 'appointments':
        return Consumer(
          builder: (context, ref, child) {
            final todaysAppointmentsAsync = ref.watch(
              todaysAppointmentsProvider,
            );
            final allPatientsAsync = ref.watch(
              patientsProvider(
                const PatientListConfig(filter: PatientFilter.all),
              ),
            );
            final emergencyAppointmentsAsync = ref.watch(
              todaysEmergencyAppointmentsProvider,
            );

            return allPatientsAsync.when(
              data: (allPatients) {
                final patientMap = {for (var p in allPatients) p.id: p};

                return todaysAppointmentsAsync.when(
                  data: (appointments) {
                    final waiting = appointments
                        .where((a) => a.status == AppointmentStatus.waiting)
                        .toList();
                    final completed = appointments
                        .where((a) => a.status == AppointmentStatus.completed)
                        .toList();

                    return emergencyAppointmentsAsync.when(
                      data: (emergencyAppointments) {
                        List<Patient> currentPatients = [];

                        switch (_appointmentTabIndex) {
                          case 0:
                            currentPatients = waiting
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            break;
                          case 1:
                            currentPatients = emergencyAppointments
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            break;
                          case 2:
                            currentPatients = completed
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            break;
                        }

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(
                                      () => _appointmentTabIndex = 0,
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _appointmentTabIndex == 0
                                          ? Colors.white.withAlpha(50)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      l10n.waiting,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: _appointmentTabIndex == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(
                                      () => _appointmentTabIndex = 1,
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _appointmentTabIndex == 1
                                          ? Colors.white.withAlpha(50)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      l10n.emergency,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: _appointmentTabIndex == 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => setState(
                                      () => _appointmentTabIndex = 2,
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _appointmentTabIndex == 2
                                          ? Colors.white.withAlpha(50)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      l10n.completed,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: _appointmentTabIndex == 2
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (currentPatients.isEmpty)
                              Text(
                                _appointmentTabIndex == 0
                                    ? l10n.noWaitingAppointments
                                    : _appointmentTabIndex == 1
                                    ? l10n.noEmergencyAppointments
                                    : l10n.noCompletedAppointments,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              DataTable(
                                border: TableBorder.all(
                                  color: Colors.white.withAlpha(100),
                                  width: 1,
                                ),
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      l10n.patientName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: currentPatients.map((patient) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        GestureDetector(
                                          onTap: () {
                                            Future.delayed(
                                              const Duration(milliseconds: 100),
                                              () {
                                                if (!mounted) return;
                                                // ignore: use_build_context_synchronously
                                                context.go(
                                                  '/patients/profile',
                                                  extra: patient,
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            '${patient.name} ${patient.familyName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            textAlign: isRTL
                                                ? TextAlign.right
                                                : TextAlign.left,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                dataTextStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      error: (e, s) => Text(
                        l10n.errorLoadingEmergencyAppointments,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  error: (e, s) => Text(
                    l10n.errorLoadingAppointments,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              error: (e, s) => Text(
                l10n.errorLoadingPatientData,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            );
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _EmergencyCounter extends StatefulWidget {
  const _EmergencyCounter({required this.emergencyCount});

  final int emergencyCount;

  @override
  State<_EmergencyCounter> createState() => _EmergencyCounterState();
}

class _EmergencyCounterState extends State<_EmergencyCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.emergencyCount > 0) {
      _animationController.repeat(reverse: true);
    }

    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.red).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _EmergencyCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.emergencyCount > 0 && !_animationController.isAnimating) {
      _animationController.repeat(reverse: true);
    } else if (widget.emergencyCount == 0 && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Text(
          'Emergency: ${widget.emergencyCount}',
          style: TextStyle(
            color: widget.emergencyCount > 0
                ? _colorAnimation.value
                : Colors.white,
            fontSize: 14,
            fontWeight: widget.emergencyCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          textAlign: TextAlign.left,
        );
      },
    );
  }
}
