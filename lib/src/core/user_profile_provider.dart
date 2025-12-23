import 'package:dentaltid/src/core/settings_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:logging/logging.dart';
import 'dart:convert';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final log = Logger('userProfileProvider');
  final firebaseService = ref.watch(firebaseServiceProvider);
  final authState = ref.watch(authStateProvider).value;
  final currentUser = authState;

  await SettingsService.instance.init();
  final settings = SettingsService.instance;

  // Load Inherited Dentist Profile (from Sync)
  UserProfile? syncedDentistProfile;
  final dentistJson = settings.getString('dentist_profile');
  if (dentistJson != null) {
    try {
      syncedDentistProfile = UserProfile.fromJson(jsonDecode(dentistJson));
    } catch (_) {}
  }

  // 1. Check for Managed User (Staff) first
  final managedJson = settings.getString('managedUserProfile');
  if (managedJson != null) {
    try {
      final staffProfile = UserProfile.fromJson(jsonDecode(managedJson));
      log.info('Detected logged in staff: ${staffProfile.username}');

      // IF STAFF: Strictly merge licensing info from synced Dentist profile if available
      if (syncedDentistProfile != null) {
        log.info('Merging license from synced dentist: ${syncedDentistProfile.plan}');
        return staffProfile.copyWith(
          plan: syncedDentistProfile.plan,
          isPremium: syncedDentistProfile.isPremium,
          trialStartDate: syncedDentistProfile.trialStartDate,
          premiumExpiryDate: syncedDentistProfile.premiumExpiryDate,
          licenseExpiry: syncedDentistProfile.licenseExpiry,
          dentistName: syncedDentistProfile.dentistName ?? staffProfile.dentistName,
          status: syncedDentistProfile.status,
          licenseKey: syncedDentistProfile.licenseKey,
        );
      }
      return staffProfile;
    } catch (e) {
      log.severe('Error parsing managed profile: $e');
    }
  }

  final rememberMe = settings.getBool('remember_me') ?? false;

  // 2. Try to get specific user profile if logged in via Firebase (Dentist)
  if (currentUser != null) {
    log.info('Fetching user profile for ${currentUser.uid}');
    try {
      final profile = await firebaseService.getUserProfile(currentUser.uid);
      if (profile != null) {
        log.info('Fetched profile online: ${profile.toJson()}');
        // Cache if Remember Me is on
        if (rememberMe) {
          await settings.setString(
            'cached_user_profile',
            jsonEncode(profile.toJson()),
          );
        }
        // Also update the 'dentist_profile' so staff get it if they sync
        await settings.setString('dentist_profile', jsonEncode(profile.toJson()));
        return profile;
      }
    } catch (e) {
      log.warning('Failed to fetch profile online: $e');
    }
  }

  // 3. Fallback to cache if Remember Me is active (Dentist)
  if (rememberMe) {
    log.info('Attempting to load cached profile');
    final cachedJson = settings.getString('cached_user_profile');
    if (cachedJson != null) {
      try {
        final profile = UserProfile.fromJson(jsonDecode(cachedJson));
        log.info('Loaded cached profile for ${profile.email}');
        return profile;
      } catch (e) {
        log.severe('Error parsing cached profile: $e');
      }
    }
  }

  log.info('No current user found or cache invalid.');
  return null;
});
