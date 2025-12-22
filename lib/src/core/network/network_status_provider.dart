import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  serverRunning,
  serverStopped,
  error
}

class NetworkStatusNotifier extends StateNotifier<ConnectionStatus> {
  NetworkStatusNotifier() : super(ConnectionStatus.disconnected);

  void setStatus(ConnectionStatus newStatus) {
    state = newStatus;
  }
}

final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, ConnectionStatus>((ref) {
  return NetworkStatusNotifier();
});

final connectedClientsCountProvider = StateProvider<int>((ref) => 0);