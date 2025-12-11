import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:logging/logging.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final log = Logger('userProfileProvider');
  final firebaseService = ref.watch(firebaseServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    log.info('Fetching user profile for ${currentUser.uid}');
    final profile = await firebaseService.getUserProfile(currentUser.uid);
    log.info('Fetched profile: ${profile?.toJson()}');
    return profile;
  }
  log.info('No current user found.');
  return null;
});
