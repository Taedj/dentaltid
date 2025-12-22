import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionStatusWidget extends ConsumerWidget {
  final UserRole userRole;
  const ConnectionStatusWidget({super.key, required this.userRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final connectedClients = ref.watch(connectedClientsCountProvider);

    IconData icon;
    Color color;
    String text;

    if (userRole == UserRole.dentist) {
      // Dentist (Server) View
      switch (status) {
        case ConnectionStatus.serverRunning:
          icon = Icons.cloud_done;
          color = Colors.green;
          text = 'Server Online ($connectedClients Staff)';
          break;
        case ConnectionStatus.serverStopped:
          icon = Icons.cloud_off;
          color = Colors.red;
          text = 'Server Offline';
          break;
        case ConnectionStatus.error:
          icon = Icons.error;
          color = Colors.deepOrange;
          text = 'Server Error';
          break;
        default:
          icon = Icons.cloud_queue;
          color = Colors.grey;
          text = 'Server Status';
      }
    } else {
      // Staff (Client) View
      switch (status) {
        case ConnectionStatus.connected:
          icon = Icons.link;
          color = Colors.green;
          text = 'Connected to Dentist';
          break;
        case ConnectionStatus.connecting:
          icon = Icons.link_off;
          color = Colors.orange;
          text = 'Connecting...';
          break;
        case ConnectionStatus.disconnected:
          icon = Icons.link_off;
          color = Colors.red;
          text = 'Disconnected';
          break;
        case ConnectionStatus.error:
          icon = Icons.error;
          color = Colors.deepOrange;
          text = 'Connection Error';
          break;
        default:
          icon = Icons.link_off;
          color = Colors.grey;
          text = 'Connection Status';
      }
    }

    return Tooltip(
      message: text,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
