import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/settings/data/staff_repository.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(DatabaseService.instance);
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(
    ref.watch(staffRepositoryProvider),
    ref.watch(firebaseServiceProvider),
    ref,
  );
});

class StaffService {
  final StaffRepository _repository;
  final FirebaseService _firebaseService;
  final Ref _ref;

  StaffService(this._repository, this._firebaseService, this._ref);

  Future<void> addStaff(UserProfile staff) async {
    // Save locally first
    await _repository.createStaff(staff);
    
    // Try to sync to Firebase in background (ignore errors for offline mode)
    try {
      await _firebaseService.saveManagedUser(staff);
    } catch (_) {
      // Offline or permission error, that's fine for now as it's saved locally
    }
  }

  Future<List<UserProfile>> getStaff(String dentistUid) async {
    // Always load from local database for instant offline access
    return await _repository.getStaffByDentist(dentistUid);
  }

  Future<void> updateStaff(UserProfile staff) async {
    await _repository.updateStaff(staff);
    
    try {
      await _firebaseService.saveManagedUser(staff);
    } catch (_) {}
  }

  Future<void> deleteStaff(String staffUid) async {
    await _repository.deleteStaff(staffUid);
    
    try {
      await _firebaseService.deleteManagedUser(staffUid);
    } catch (_) {}
  }

  Future<UserProfile?> authenticateStaff(String dentistUid, String username, String pin) async {
    // Check local first
    var localUser = await _repository.getStaffByUsernameAndPin(dentistUid, username, pin);
    
    // Fallback to Firebase if online
    if (localUser == null) {
      try {
        localUser = await _firebaseService.authenticateManagedUser(dentistUid, username, pin);
      } catch (_) {
        return null;
      }
    }

    if (localUser != null) {
       // Sync subscription status from cached Dentist profile (if available)
       try {
         final prefs = await SharedPreferences.getInstance();
         final cachedDentistJson = prefs.getString('cached_user_profile');
         if (cachedDentistJson != null) {
            final dentistProfile = UserProfile.fromJson(jsonDecode(cachedDentistJson));
            
            // Only sync if this dentist manages this user
            if (dentistProfile.uid == localUser?.managedByDentistId) {
               localUser = localUser!.copyWith(
                  plan: dentistProfile.plan,
                  status: dentistProfile.status,
                  isPremium: dentistProfile.isPremium,
                  trialStartDate: dentistProfile.trialStartDate,
                  premiumExpiryDate: dentistProfile.premiumExpiryDate,
                  licenseExpiry: dentistProfile.licenseExpiry,
               );
               // Update local DB with synced data
               await _repository.updateStaff(localUser!);
            }
         }
       } catch (e) {
         // Ignore sync errors during auth
       }
    }
    
    return localUser;
  }
}