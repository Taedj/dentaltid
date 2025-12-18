import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final log = Logger('userProfileProvider');
  final firebaseService = ref.watch(firebaseServiceProvider);
  final authState = ref.watch(authStateProvider).value;
  final currentUser = authState; // Use the value from authStateProvider
  
  final prefs = await SharedPreferences.getInstance();

  // 1. Check for Managed User (Staff) first
  final managedJson = prefs.getString('managedUserProfile');
  if (managedJson != null) {
    try {
      final profile = UserProfile.fromJson(jsonDecode(managedJson));
      log.info('Detected logged in staff: ${profile.username}');
      return profile;
    } catch (e) {
      log.severe('Error parsing managed profile: $e');
    }
  }

  final rememberMe = prefs.getBool('remember_me') ?? false;

  // 2. Try to get specific user profile if logged in via Firebase (Dentist)
  if (currentUser != null) {
    log.info('Fetching user profile for ${currentUser.uid}');
    try {
      final profile = await firebaseService.getUserProfile(currentUser.uid);
      if (profile != null) {
        log.info('Fetched profile online: ${profile.toJson()}');
        // Cache if Remember Me is on
        if (rememberMe) {
           await prefs.setString('cached_user_profile', jsonEncode(profile.toJson()));
        }
        return profile;
      }
    } catch (e) {
      log.warning('Failed to fetch profile online: $e');
    }
  }

  // 2. Fallback to cache if Remember Me is active
  if (rememberMe) {
    log.info('Attempting to load cached profile');
    final cachedJson = prefs.getString('cached_user_profile');
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
