import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/patients/domain/patient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClinicUsageState {
  final int patientCount;
  final int appointmentCount;
  final int inventoryCount;
  final int daysLeft;
  final bool isPremium;
  final bool isExpired;
  final bool isCrown;
  final bool hasReachedPatientLimit;
  final bool hasReachedAppointmentLimit;
  final bool hasReachedInventoryLimit;

  ClinicUsageState({
    required this.patientCount,
    required this.appointmentCount,
    required this.inventoryCount,
    required this.daysLeft,
    required this.isPremium,
    required this.isCrown,
    required this.isExpired,
    required this.hasReachedPatientLimit,
    required this.hasReachedAppointmentLimit,
    required this.hasReachedInventoryLimit,
  });

  bool get shouldLockApp => !isPremium && daysLeft <= 0;
}

final clinicUsageProvider = Provider<ClinicUsageState>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  final patientsResult = ref
      .watch(
        patientsProvider(
          const PatientListConfig(filter: PatientFilter.all, pageSize: 1),
        ),
      )
      .value;

  final appointmentsResult = ref
      .watch(appointmentsProvider(const AppointmentListConfig(pageSize: 1)))
      .value;

  final inventoryResult = ref
      .watch(inventoryItemsProvider(const InventoryListConfig(pageSize: 1)))
      .value;

  final patientCount = patientsResult?.totalCount ?? 0;
  final appointmentCount = appointmentsResult?.totalCount ?? 0;
  final inventoryCount = inventoryResult?.totalCount ?? 0;

  final isPremium = userProfile?.isPremium ?? false;

  // --- CLOCK GUARD LOGIC (Offline Security) ---
  final settings = SettingsService.instance;
  final lastSeenStr = settings.getString('last_seen_date');
  DateTime lastSeen = DateTime.now();
  if (lastSeenStr != null) {
    lastSeen = DateTime.tryParse(lastSeenStr) ?? DateTime.now();
  }

  final now = DateTime.now();
  // Effective current time is the maximum of real time and last recorded time
  final effectiveNow = now.isBefore(lastSeen) ? lastSeen : now;

  // Progressively update last_seen_date (fire and forget as it's a local setting save)
  if (now.isAfter(lastSeen)) {
    settings.setString('last_seen_date', now.toIso8601String());
  }

  // Subscription Days Left Logic
  int daysLeft = 30;
  if (userProfile != null) {
    if (isPremium && userProfile.premiumExpiryDate != null) {
      daysLeft = userProfile.premiumExpiryDate!.difference(effectiveNow).inDays;
      if (daysLeft < 0) daysLeft = 0;
    } else if (!isPremium) {
      final trialStart = userProfile.trialStartDate ?? userProfile.createdAt;
      final daysUsed = effectiveNow.difference(trialStart).inDays;
      daysLeft = (30 - daysUsed).clamp(0, 30);
    }
  }

  return ClinicUsageState(
    patientCount: patientCount,
    appointmentCount: appointmentCount,
    inventoryCount: inventoryCount,
    daysLeft: daysLeft,
    isPremium: isPremium,
    isCrown:
        userProfile?.plan == SubscriptionPlan.enterprise ||
        userProfile?.plan == SubscriptionPlan.trial,
    isExpired: daysLeft <= 0,
    hasReachedPatientLimit: !isPremium && patientCount >= 100,
    hasReachedAppointmentLimit: !isPremium && appointmentCount >= 100,
    hasReachedInventoryLimit: !isPremium && inventoryCount >= 100,
  );
});
