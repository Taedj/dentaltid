import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/sync_manager.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/network_discovery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async';

final appInitializerProvider = Provider((ref) => AppInitializer(ref));

class AppInitializer {
  final Ref _ref;
  final Logger _logger = Logger('AppInitializer');
  bool _isInitialized = false;

  AppInitializer(this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _logger.info('Initializing application sync services...');
    
    try {
      // Small delay to allow SharedPreferences to settle during login flow
      await Future.delayed(const Duration(milliseconds: 500));

      // 1. Get current user profile
      final userProfile = await _ref.read(userProfileProvider.future);
      if (userProfile == null) {
        _logger.info('No user logged in, skipping sync initialization');
        return;
      }

      final syncManager = _ref.read(syncManagerProvider);

      // 2. Initialize based on role
      if (userProfile.role == UserRole.dentist) {
        _logger.info('User is Dentist, starting as Sync Server');
        await syncManager.initializeAsServer(userProfile);
      } else {
        _logger.info('User is Staff, starting Network Discovery to find Dentist');
        _startStaffSync(syncManager, userProfile);
      }

      _isInitialized = true;
    } catch (e) {
      _logger.severe('App initialization failed: $e');
    }
  }

  void _startStaffSync(SyncManager syncManager, UserProfile userProfile) {
    final discoveryService = NetworkDiscoveryService();
    
    // Start discovery
    discoveryService.startDiscovery();
    
    // Listen for available servers
    StreamSubscription? subscription;
    subscription = discoveryService.discoveredServers.listen((servers) async {
      if (servers.isNotEmpty) {
        _logger.info('Discovered clinic server: ${servers.first}');
        
        try {
          await syncManager.initializeAsClient(
            server: servers.first, 
            userProfile: userProfile
          );
          
          // Once connected, we can stop discovery to save resources
          discoveryService.stopDiscovery();
          subscription?.cancel();
        } catch (e) {
          _logger.warning('Failed to connect to discovered server: $e');
        }
      }
    });
    
    // Safety: stop discovery after some time if nothing found
    Future.delayed(const Duration(minutes: 5), () {
      discoveryService.stopDiscovery();
      subscription?.cancel();
    });
  }
}
