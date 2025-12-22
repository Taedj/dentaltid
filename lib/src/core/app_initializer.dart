import 'dart:async';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dentaltid/src/core/user_model.dart';

final appInitializerProvider = Provider((ref) => AppInitializer(ref));

class AppInitializer {
  final Ref _ref;
  final Logger _logger = Logger('AppInitializer');
  bool _isInitialized = false;

  AppInitializer(this._ref);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _logger.info('Initializing application...');
    
    try {
      final userProfile = await _ref.read(userProfileProvider.future);
      
      final prefs = await SharedPreferences.getInstance();
      final roleString = prefs.getString('userRole');
      UserRole? currentUserRole;
      if (roleString != null) {
        currentUserRole = UserRole.values.firstWhere(
          (e) => e.toString() == roleString,
          orElse: () => UserRole.dentist,
        );
      } else {
        currentUserRole = userProfile?.role;
      }

      if (currentUserRole == UserRole.dentist) {
        final autoStartServer = prefs.getBool('autoStartServer') ?? false;
        final serverPort = int.tryParse(prefs.getString('serverPort') ?? '8080') ?? 8080;

        if (autoStartServer) {
          _logger.info('Auto-starting SyncServer on port $serverPort...');
          try {
            await _ref.read(syncServerProvider).start(serverPort);
            _logger.info('SyncServer auto-started successfully.');
          } catch (e) {
            _logger.severe('Failed to auto-start SyncServer: $e');
            _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
          }
        } else {
          _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.serverStopped);
        }
      } else if (currentUserRole != null && (currentUserRole == UserRole.assistant || currentUserRole == UserRole.receptionist)) {
        final autoConnectClient = prefs.getBool('autoConnectClient') ?? false;
        final clientIp = prefs.getString('autoConnectIp');
        final clientPort = int.tryParse(prefs.getString('autoConnectPort') ?? '8080') ?? 8080;

        if (autoConnectClient && clientIp != null && clientIp.isNotEmpty) {
          _logger.info('Auto-connecting SyncClient to $clientIp:$clientPort...');
          _autoConnectWithRetry(clientIp, clientPort);
        } else {
          _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.disconnected);
        }
      } else {
        _logger.info('User is not a Dentist or Staff, no auto-network action.');
        _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.disconnected);
      }
      
      _isInitialized = true;
    } catch (e) {
      _logger.severe('App initialization failed: $e');
      _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
    }
  }

  Future<void> _autoConnectWithRetry(String ip, int port) async {
    const int maxRetries = 5;
    const Duration retryDelay = Duration(seconds: 5);

    for (int i = 0; i < maxRetries; i++) {
      _logger.info('Attempting auto-connect to $ip:$port (Attempt ${i + 1}/$maxRetries)...');
      try {
        await _ref.read(syncClientProvider).connect(ip, port);
        _logger.info('SyncClient auto-connected successfully.');
        _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.connected);
        return; 
      } catch (e) {
        _logger.warning('Auto-connect failed: $e. Retrying in ${retryDelay.inSeconds} seconds...');
        _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.connecting);
        await Future.delayed(retryDelay);
      }
    }
    _logger.severe('Failed to auto-connect to $ip:$port after $maxRetries attempts.');
    _ref.read(networkStatusProvider.notifier).setStatus(ConnectionStatus.error);
  }
}
