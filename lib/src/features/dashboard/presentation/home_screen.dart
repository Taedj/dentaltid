import 'dart:ui';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/inventory/domain/inventory_item.dart';
import 'package:dentaltid/src/core/clinic_usage_provider.dart';
import 'package:dentaltid/src/features/developer/data/broadcast_service.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'dart:convert';
import 'package:dentaltid/src/core/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final jsonString = SettingsService.instance.getString(
      'dismissed_broadcasts',
    );
    if (jsonString != null) {
      try {
        setState(() {
          _dismissedBroadcastIds = List<String>.from(jsonDecode(jsonString));
        });
      } catch (e) {
        // Ignore parse errors
      }
    }
  }

  Future<void> _dismissBroadcast(String id) async {
    if (_dismissedBroadcastIds.contains(id)) return;

    setState(() {
      _dismissedBroadcastIds.add(id);
    });
    await SettingsService.instance.setString(
      'dismissed_broadcasts',
      jsonEncode(_dismissedBroadcastIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayPatientsAsyncValue = ref.watch(
      patientsProvider(const PatientListConfig(filter: PatientFilter.today)),
    );
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.dashboard),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainer,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 56),
            // --- BROADCAST BANNER ---
            _buildBroadcastBanner(),

            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: const _DashboardHeader(),
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
                      cardWidth =
                          constraints.maxWidth * 0.85; // Mobile full width
                    }
                    // Adjust for mobile wrap
                    if (constraints.maxWidth < 800) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            _buildPatientCard(
                              cardWidth,
                              todayPatientsAsyncValue,
                              l10n,
                            ),
                            const SizedBox(height: 16),
                            _buildInventoryCard(
                              cardWidth,
                              inventoryItemsAsyncValue,
                              l10n,
                            ),
                            const SizedBox(height: 16),
                            _buildAppointmentsCard(cardWidth, l10n),
                          ],
                        ),
                      );
                    }

                    double cardHeight =
                        cardWidth * 1.2; // Slightly shorter for modern look
                    double spacing = cardWidth * 0.05;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start, // Align top
                      children: [
                        _buildPatientCard(
                          cardWidth,
                          todayPatientsAsyncValue,
                          l10n,
                          height: cardHeight,
                        ),
                        SizedBox(width: spacing),
                        _buildInventoryCard(
                          cardWidth,
                          inventoryItemsAsyncValue,
                          l10n,
                          height: cardHeight,
                        ),
                        SizedBox(width: spacing),
                        _buildAppointmentsCard(
                          cardWidth,
                          l10n,
                          height: cardHeight,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastBanner() {
    return StreamBuilder<List<BroadcastModel>>(
      stream: BroadcastService().getActiveBroadcasts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleBroadcasts = snapshot.data!
            .where((b) => !_dismissedBroadcastIds.contains(b.id))
            .toList();

        if (visibleBroadcasts.isEmpty) return const SizedBox.shrink();
        final latest = visibleBroadcasts.first;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getBroadcastColor(latest.type).withValues(alpha: 0.1),
            border: Border.all(color: _getBroadcastColor(latest.type)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _getBroadcastIcon(latest.type),
                color: _getBroadcastColor(latest.type),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getBroadcastColor(latest.type),
                      ),
                    ),
                    Text(latest.message),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () => _dismissBroadcast(latest.id),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildPatientCard(
    double width,
    AsyncValue<List<Patient>> data,
    AppLocalizations l10n, {
    double? height,
  }) {
    return _FlipCard3D(
      width: width,
      height: height ?? width * 1.2,
      frontTitle: l10n.patients,
      frontIcon: LucideIcons.users,
      frontGradient: [
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.7),
      ],
      backTitle: l10n.viewDetails,
      backIcon: LucideIcons.eye,
      onTap: () => context.go('/patients'),
      cardType: 'patients',
      kpiBuilder: () => data.when(
        data: (p) => Text(
          l10n.activeStatus(p.length),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        loading: () => const SizedBox(),
        error: (_, _) => const SizedBox(),
      ),
      content: data.when(
        data: (patients) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayCount(patients.length),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24, // Bold Number
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.scheduledVisits,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        loading: () => const CircularProgressIndicator(color: Colors.white),
        error: (e, s) =>
            const Icon(LucideIcons.alertCircle, color: Colors.white),
      ),
    );
  }

  Widget _buildInventoryCard(
    double width,
    AsyncValue<List<InventoryItem>> data,
    AppLocalizations l10n, {
    double? height,
  }) {
    return _FlipCard3D(
      width: width,
      height: height ?? width * 1.2,
      frontTitle: l10n.criticalAlerts,
      frontIcon: LucideIcons.alertTriangle, // ShieldAlert equivalent
      frontGradient: data.maybeWhen(
        data: (items) {
          final now = DateTime.now();
          final expiringSoonCount = items.where((item) {
            final daysLeft = item.expirationDate.difference(now).inDays;
            return daysLeft >= 0 && daysLeft < item.thresholdDays;
          }).length;
          final lowStockCount = items
              .where((item) => item.quantity <= item.lowStockThreshold)
              .length;

          if (expiringSoonCount > 0 || lowStockCount > 0) {
            return [
              AppColors.warning,
              AppColors.error,
            ]; // Warning/Error Gradient
          }
          return [AppColors.success, Color(0xFF27AE60)]; // Healthy Gradient
        },
        orElse: () => [AppColors.success, Color(0xFF27AE60)],
      ),
      backTitle: l10n.viewCritical,
      backIcon: LucideIcons.alertOctagon,
      onTap: () => context.go('/inventory'),
      cardType: 'emergency',
      kpiBuilder: () => data.when(
        data: (items) {
          final now = DateTime.now();
          final low = items
              .where((i) => i.quantity <= i.lowStockThreshold)
              .length;
          final expiring = items.where((item) {
            final daysLeft = item.expirationDate.difference(now).inDays;
            return daysLeft >= 0 && daysLeft < item.thresholdDays;
          }).length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                l10n.expiringLabel(expiring),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Container(width: 1, height: 12, color: Colors.white54),
              Text(
                l10n.lowStockLabelText(low),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(),
        error: (_, _) => const SizedBox(),
      ),
      content: data.when(
        data: (items) {
          final now = DateTime.now();
          final expiringSoonCount = items.where((item) {
            final daysLeft = item.expirationDate.difference(now).inDays;
            return daysLeft >= 0 && daysLeft < item.thresholdDays;
          }).length;
          final lowStockCount = items
              .where((item) => item.quantity <= item.lowStockThreshold)
              .length;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expiringSoonCount > 0 || lowStockCount > 0) ...[
                Text(
                  "${expiringSoonCount + lowStockCount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.actionNeeded,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                const Icon(
                  LucideIcons.checkCircle,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.allGood,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const CircularProgressIndicator(color: Colors.white),
        error: (e, s) =>
            const Icon(LucideIcons.alertCircle, color: Colors.white),
      ),
    );
  }

  Widget _buildAppointmentsCard(
    double width,
    AppLocalizations l10n, {
    double? height,
  }) {
    return _FlipCard3D(
      width: width,
      height: height ?? width * 1.2,
      frontTitle: l10n.todaysAppointmentsFlow,
      frontIcon: LucideIcons.clock,
      frontGradient: [
        AppColors.secondary,
        AppColors.secondary.withValues(alpha: 0.7),
      ],
      backTitle: l10n.viewAppointments,
      backIcon: LucideIcons.calendar,
      onTap: () => context.go('/appointments'),
      cardType: 'appointments',
      kpiBuilder: () => Consumer(
        builder: (ctx, ref, _) {
          final apps =
              ref.watch(todaysAppointmentsProvider).asData?.value ?? [];
          final emergencies =
              ref.watch(todaysEmergencyAppointmentsProvider).asData?.value ??
              [];
          final waiting = apps
              .where((a) => a.status == AppointmentStatus.waiting)
              .length;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '$waiting Waiting',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (emergencies.isNotEmpty) ...[
                Container(width: 1, height: 12, color: Colors.white54),
                Text(
                      l10n.emergencyCountLabel(emergencies.length),
                      style: const TextStyle(
                        color: AppColors.highlight,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1200.ms, color: Colors.white24)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 600.ms,
                    ),
              ],
            ],
          );
        },
      ),
      content: Consumer(
        builder: (context, ref, child) {
          final todaysAppointmentsAsync = ref.watch(todaysAppointmentsProvider);
          return todaysAppointmentsAsync.when(
            data: (appointments) {
              final inProgress = appointments
                  .where((a) => a.status == AppointmentStatus.inProgress)
                  .length;
              final completed = appointments
                  .where((a) => a.status == AppointmentStatus.completed)
                  .length;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${appointments.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.periodToday, // Total Today
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMiniStatusDot(Colors.white, l10n.activeStatus(inProgress)),
                      const SizedBox(width: 8),
                      _buildMiniStatusDot(Colors.white70, l10n.doneStatus(completed)),
                    ],
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(color: Colors.white),
            error: (_, _) =>
                const Icon(LucideIcons.alertCircle, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildMiniStatusDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsyncValue = ref.watch(userProfileProvider);
    final usage = ref.watch(clinicUsageProvider);
    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context)!;

    return userProfileAsyncValue.when(
      data: (userProfile) {
        final isDentist = userProfile?.role == UserRole.dentist;
        final displayName = (isDentist ? userProfile?.dentistName : userProfile?.fullName) ?? userProfile?.dentistName ?? 'User';
        final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
        final greetingPrefix = isDentist ? 'Dr. ' : '';
        
        // Subscription Status Logic
        final isPremium = usage.isPremium;
        final daysLeft = usage.daysLeft;
        final statusText = isPremium 
            ? l10n.premiumDaysLeft(daysLeft) 
            : l10n.trialVersionDaysLeft(daysLeft);
        final statusColor = isPremium ? AppColors.success : AppColors.warning;

        // Dynamic Greeting
        final hour = DateTime.now().hour;
        String greeting = l10n.goodMorning;
        if (hour >= 12 && hour < 17) {
          greeting = l10n.goodAfternoon;
        } else if (hour >= 17) {
          greeting = l10n.goodEvening;
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "$greeting 👋 $greetingPrefix$displayName",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(delay: 2000.ms, duration: 1000.ms),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clinicRunningSmoothly,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const _LiveClock(),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("Welcome Back"),
      ),
    );
  }
}

Color _getBroadcastColor(String type) {
  switch (type) {
    case 'warning':
      return AppColors.warning;
    case 'maintenance':
      return AppColors.error;
    default:
      return AppColors.primary;
  }
}

IconData _getBroadcastIcon(String type) {
  switch (type) {
    case 'warning':
      return LucideIcons.alertTriangle;
    case 'maintenance':
      return LucideIcons.wrench;
    default:
      return LucideIcons.info;
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
  final Widget Function() kpiBuilder;

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
    required this.kpiBuilder,
  });

  @override
  ConsumerState<_FlipCard3D> createState() => _FlipCard3DState();
}

class _FlipCard3DState extends ConsumerState<_FlipCard3D>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  bool _isHovering = false;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          if (_controller.isAnimating) return;
          if (_isFront) {
            _controller.forward();
            setState(() => _isFront = false);
          } else {
            _controller.reverse();
            setState(() => _isFront = true);
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * 3.14159;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle)
              ..setTranslationRaw(
                0.0,
                _isHovering ? -10.0 : 0.0,
                0.0,
              ); // Floating effect

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _isFront
                  ? _buildFrontCard()
                  : Transform(
                      transform: Matrix4.rotationY(3.14159),
                      alignment: Alignment.center,
                      child: _buildBackCard(),
                    ),
            );
          },
        ),
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
            color: widget.frontGradient.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            left: -20,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.frontIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Icon(
                      LucideIcons.arrowRight,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.content,
                    const SizedBox(height: 8),
                    Text(
                      widget.frontTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // KPI Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.kpiBuilder(),
                ),
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
        color: Theme.of(context).cardTheme.color,
        border: Border.all(
          color: widget.frontGradient.first.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8), // Tighter padding
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                widget.backIcon,
                color: widget.frontGradient.first,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.backTitle,
                  style: TextStyle(
                    color: widget.frontGradient.first,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(child: _buildBackContent()),
        ],
      ),
    );
  }

  // State for tab indices
  int _appointmentTabIndex = 0;
  int _criticalAlertTabIndex = 0;

  Widget _buildBackContent() {
    final l10n = AppLocalizations.of(context)!;

    if (widget.cardType == 'patients') {
      return Consumer(
        builder: (ctx, ref, _) {
          final patientsAsync = ref.watch(
            patientsProvider(
              const PatientListConfig(filter: PatientFilter.today),
            ),
          );
          return patientsAsync.when(
            data: (patients) {
              if (patients.isEmpty)
                return Center(
                  child: Text(
                    l10n.noPatientsToday,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                );
              // Sort by creation time to ensure consistent order
              final sorted = List<Patient>.from(patients)
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final p = sorted[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      "${index + 1}.",
                      style: TextStyle(
                        color: widget.frontGradient.first,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(
                      "${p.name} ${p.familyName}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: 14),
                    onTap: () => context.go('/patients/profile', extra: p),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox(),
          );
        },
      );
    } else if (widget.cardType == 'emergency') {
      return Consumer(
        builder: (ctx, ref, _) {
          final items = ref.watch(inventoryItemsProvider).asData?.value ?? [];
          final now = DateTime.now();

          final expiringSoon = items.where((item) {
            final daysLeft = item.expirationDate.difference(now).inDays;
            return daysLeft >= 0 && daysLeft < item.thresholdDays;
          }).toList();

          final lowStock = items
              .where((i) => i.quantity <= i.lowStockThreshold)
              .toList();

          return Column(
            children: [
              Row(
                children: [
                  _buildSmallTab(
                    l10n.expiringSoon,
                    _criticalAlertTabIndex == 0,
                    AppColors.error,
                    () => setState(() => _criticalAlertTabIndex = 0),
                  ),
                  _buildSmallTab(
                    l10n.lowStock,
                    _criticalAlertTabIndex == 1,
                    AppColors.warning,
                    () => setState(() => _criticalAlertTabIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _criticalAlertTabIndex == 0
                    ? (expiringSoon.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noExpiringSoonItems,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: expiringSoon.length,
                              itemBuilder: (context, index) {
                                final i = expiringSoon[index];
                                final days = i.expirationDate
                                    .difference(now)
                                    .inDays;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                    "${index + 1}.",
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  title: Text(
                                    i.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    "$days d",
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ))
                    : (lowStock.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noLowStockItems,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: lowStock.length,
                              itemBuilder: (context, index) {
                                final i = lowStock[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Text(
                                    "${index + 1}.",
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  title: Text(
                                    i.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    "Qty: ${i.quantity}",
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            )),
              ),
            ],
          );
        },
      );
    } else if (widget.cardType == 'appointments') {
      return Consumer(
        builder: (ctx, ref, _) {
          final appsAsync = ref.watch(todaysAppointmentsProvider);
          final emergenciesAsync = ref.watch(
            todaysEmergencyAppointmentsProvider,
          );

          return appsAsync.when(
            data: (apps) {
              final emergencies = emergenciesAsync.asData?.value ?? [];
              final emergencyIds = emergencies.map((e) => e.id).toSet();

              final waiting = apps
                  .where(
                    (a) =>
                        a.status == AppointmentStatus.waiting &&
                        !emergencyIds.contains(a.id),
                  )
                  .toList();
              final inProgress = apps
                  .where((a) => a.status == AppointmentStatus.inProgress)
                  .toList();
              final completed = apps
                  .where((a) => a.status == AppointmentStatus.completed)
                  .toList();

              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSmallTab(
                          l10n.waiting,
                          _appointmentTabIndex == 0,
                          AppColors.primary,
                          () => setState(() => _appointmentTabIndex = 0),
                        ),
                        _buildSmallTab(
                          l10n.emergency,
                          _appointmentTabIndex == 1,
                          AppColors.error,
                          () => setState(() => _appointmentTabIndex = 1),
                        ),
                        _buildSmallTab(
                          l10n.inProgress,
                          _appointmentTabIndex == 2,
                          AppColors.warning,
                          () => setState(() => _appointmentTabIndex = 2),
                        ),
                        _buildSmallTab(
                          l10n.completed,
                          _appointmentTabIndex == 3,
                          AppColors.success,
                          () => setState(() => _appointmentTabIndex = 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        List<Appointment> currentList = [];
                        if (_appointmentTabIndex == 0) {
                          currentList = waiting;
                        } else if (_appointmentTabIndex == 1) {
                          currentList = emergencies;
                        } else if (_appointmentTabIndex == 2) {
                          currentList = inProgress;
                        } else {
                          currentList = completed;
                        }

                        if (currentList.isEmpty)
                          return Center(
                            child: Text(
                              l10n.noAppointmentsFound,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          );

                        // Sort by time
                        final sorted = List<Appointment>.from(currentList)
                          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final a = sorted[index];
                            final patientAsync = ref.watch(
                              patientProvider(a.patientId),
                            );

                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Text(
                                "${index + 1}.",
                                style: TextStyle(
                                  color: widget.frontGradient.first,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              title: patientAsync.when(
                                data: (p) => Text(
                                  "${p?.name} ${p?.familyName}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                loading: () => const Text("..."),
                                error: (_, _) => const Text("Error"),
                              ),
                              subtitle: Text(
                                DateFormat('HH:mm').format(a.dateTime),
                                style: const TextStyle(fontSize: 10),
                              ),
                              trailing: const Icon(
                                LucideIcons.chevronRight,
                                size: 14,
                              ),
                              onTap: () =>
                                  context.go('/appointments/edit', extra: a),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox(),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSmallTab(
    String label,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Stream<DateTime> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _timerStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final dateStr = DateFormat.yMMMMEEEEd(
          Localizations.localeOf(context).toString(),
        ).format(now);
        final timeStr = DateFormat.Hms(
          Localizations.localeOf(context).toString(),
        ).format(now);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                // Using monospaced font for numbers prevents jitter
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
