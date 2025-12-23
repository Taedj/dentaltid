import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  handshakeAccepted, // New state: server reached, waiting for DB export
  syncing, // Add new state for when initial data transfer is in progress
  synced, // Formerly 'connected'
  serverRunning,
  serverStopped,
  error,
}

class NetworkStatusNotifier extends StateNotifier<ConnectionStatus> {
  NetworkStatusNotifier() : super(ConnectionStatus.disconnected);

  void setStatus(ConnectionStatus newStatus) {
    state = newStatus;
  }
}

final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, ConnectionStatus>((ref) {
      return NetworkStatusNotifier();
    });

final connectedClientsCountProvider = StateProvider<int>((ref) => 0);
final connectedStaffNamesProvider = StateProvider<List<String>>((ref) => []);
