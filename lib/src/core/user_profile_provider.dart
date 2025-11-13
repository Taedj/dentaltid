import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/user_model.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    return await firebaseService.getUserProfile(currentUser.uid);
  }
  return null;
});
