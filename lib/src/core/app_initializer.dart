import 'package:dentaltid/src/core/user_profile_provider.dart';
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
    
    _logger.info('Initializing application...');
    
    try {
      // Get current user profile just to ensure it's loaded
      await _ref.read(userProfileProvider.future);
      _isInitialized = true;
    } catch (e) {
      _logger.severe('App initialization failed: $e');
    }
  }
}
