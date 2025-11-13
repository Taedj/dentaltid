import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart'; // Import the new provider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayPatientsAsyncValue = ref.watch(
      patientsProvider(PatientFilter.today),
    );
    final inventoryItemsAsyncValue = ref.watch(inventoryItemsProvider);
    final l10n = AppLocalizations.of(context)!;
    final userProfileAsyncValue = ref.watch(userProfileProvider); // Watch the user profile provider

    return Scaffold(
      body: Column(
        children: [
          // Header with welcome message, date, and time
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2, // Give more space to the welcome message
                  child: userProfileAsyncValue.when(
                    data: (userProfile) {
                      final dentistName = userProfile?.dentistName ?? 'Dr.';
                      return Text(
                        '${l10n.welcomeDr} $dentistName',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                      );
                    },
                    loading: () => Text(
                      l10n.welcomeDr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    error: (e, s) => Text(
                      l10n.welcomeDr,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1, // Space for date and time
                  child: StreamBuilder<DateTime>(
                    stream: Stream.periodic(
                      const Duration(seconds: 1),
                      (_) => DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      final currentTime = snapshot.data ?? DateTime.now();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(currentTime),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            DateFormat('HH:mm:ss').format(currentTime),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Centered 3D Flip Cards
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive card sizing based on screen width
                  double cardWidth;
                  if (constraints.maxWidth > 1400) {
                    cardWidth = constraints.maxWidth * 0.26; // Larger screens
                  } else if (constraints.maxWidth > 1000) {
                    cardWidth = constraints.maxWidth * 0.29; // Medium screens
                  } else if (constraints.maxWidth > 800) {
                    cardWidth = constraints.maxWidth * 0.32; // Smaller screens
                  } else {
                    cardWidth =
                        constraints.maxWidth * 0.36; // Mobile/small screens
                  }
                  double cardHeight = cardWidth * 1.4; // Maintain aspect ratio

                  // Responsive spacing and text scaling
                  double spacing = cardWidth * 0.08; // 8% of card width
                  double titleFontSize = cardWidth * 0.08; // 8% of card width
                  double numberFontSize = cardWidth * 0.14; // 14% of card width
                  double subtitleFontSize =
                      cardWidth * 0.06; // 6% of card width

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Patients Card
                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.patients,
                        frontIcon: Icons.people,
                        frontGradient: [
                          Colors.blue.shade400,
                          Colors.blue.shade800,
                        ],
                        backTitle: 'View Details',
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
                                'Today: ${patients.length}',
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

                      // Emergency Alerts Card
                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.emergencyAlerts,
                        frontIcon: Icons.warning_amber,
                        frontGradient: [
                          Colors.red.shade400,
                          Colors.red.shade800,
                        ],
                        backTitle: 'View Emergencies',
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
                              return daysLeft >= 0 && daysLeft < 30;
                            }).length;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expiring Soon: $expiringSoonCount',
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

                      // Appointments Card
                      _FlipCard3D(
                        width: cardWidth,
                        height: cardHeight,
                        frontTitle: l10n.todaysAppointmentsFlow,
                        frontIcon: Icons.access_time,
                        frontGradient: [
                          Colors.teal.shade400,
                          Colors.teal.shade800,
                        ],
                        backTitle: 'View Appointments',
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

                            return todaysAppointmentsAsync.when(
                              data: (appointments) {
                                final waiting = appointments
                                    .where(
                                      (a) =>
                                          a.status == AppointmentStatus.waiting,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final emergencyAppointmentsAsync = ref
                                            .watch(
                                              todaysEmergencyAppointmentsProvider,
                                            );
                                        return emergencyAppointmentsAsync.when(
                                          data: (emergencyAppointments) => Text(
                                            'Emergency: ${emergencyAppointments.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                          loading: () => const Text(
                                            'Emergency: ...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          error: (e, s) => const Text(
                                            'Emergency: 0',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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

class _FlipCard3D extends StatefulWidget {
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
    this.titleFontSize = 18.0,
    this.numberFontSize = 32.0,
    this.subtitleFontSize = 12.0,
  });

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

  @override
  State<_FlipCard3D> createState() => _FlipCard3DState();
}

class _FlipCard3DState extends State<_FlipCard3D>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _borderController;
  late Animation<double> _borderAnimation;
  bool _isFront = true;
  int _appointmentTabIndex = 0;

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
        // Flip to back side when mouse enters the card
        if (_isFront) {
          _controller.forward();
          setState(() {
            _isFront = false;
          });
        }
      },
      onExit: (_) {
        // Flip back to front side when mouse leaves the card
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

          // Animated border color
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
                      transform: Matrix4.rotationY(
                        3.14159,
                      ), // Flip text back to readable orientation
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
          // Decorative circles (adapted from the HTML design)
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

          // Content
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
    // Get text direction based on locale
    final locale = Localizations.localeOf(context);
    final isRTL = ['ar', 'he', 'fa', 'ur'].contains(locale.languageCode);

    switch (widget.cardType) {
      case 'patients':
        return Consumer(
          builder: (context, ref, child) {
            final todayPatientsAsync = ref.watch(
              patientsProvider(PatientFilter.today),
            );
            return todayPatientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Text(
                    'No patients today',
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
                        'Patient Name',
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
                          Text(
                            '${patient.name} ${patient.familyName}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
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
              error: (e, s) => const Text(
                'Error loading patients',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  return daysLeft >= 0 && daysLeft < 30;
                }).toList();

                if (expiringSoon.isEmpty) {
                  return const Text(
                    'No items expiring soon',
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
                        'Item Name',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: expiringSoon.map((item) {
                    final daysLeft = item.expirationDate.difference(now).inDays;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.name,
                            style: const TextStyle(color: Colors.white),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${daysLeft}d left',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
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
              error: (e, s) => const Text(
                'Error loading inventory',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
              patientsProvider(PatientFilter.all),
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
                        String tabTitle = '';

                        switch (_appointmentTabIndex) {
                          case 0:
                            currentPatients = waiting
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            tabTitle = 'Waiting';
                            break;
                          case 1:
                            currentPatients = emergencyAppointments
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            tabTitle = 'Emergency';
                            break;
                          case 2:
                            currentPatients = completed
                                .map((a) => patientMap[a.patientId])
                                .whereType<Patient>()
                                .toList();
                            tabTitle = 'Completed';
                            break;
                        }

                        return Column(
                          children: [
                            // Tab buttons
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
                                      'Waiting',
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
                                      'Emergency',
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
                                      'Completed',
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
                            // Table
                            if (currentPatients.isEmpty)
                              Text(
                                'No $tabTitle appointments',
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
                                      'Patient Name',
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
                                        Text(
                                          '${patient.name} ${patient.familyName}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          textAlign: isRTL
                                              ? TextAlign.right
                                              : TextAlign.left,
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
                      error: (e, s) => const Text(
                        'Error loading emergency appointments',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                  loading: () => const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  error: (e, s) => const Text(
                    'Error loading appointments',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              error: (e, s) => const Text(
                'Error loading patient data',
                style: TextStyle(color: Colors.white70, fontSize: 12),
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
