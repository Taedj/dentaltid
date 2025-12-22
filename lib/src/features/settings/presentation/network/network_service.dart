import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class NetworkService {
  final _log = Logger('NetworkService');

  Future<List<String>> getLocalIpAddresses() async {
    final List<String> addresses = [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          addresses.add(addr.address);
        }
      }
    } catch (e) {
      _log.severe('Error fetching IPs: $e');
    }
    return addresses;
  }

  Future<void> openFirewallPort(int port) async {
    if (!Platform.isWindows) return;

    try {
      // Execute the .bat script as admin
      // 'runas' verb is handled by shell execution, but creating a process
      // directly might not trigger UAC unless we use 'runas' explicitly via shell command
      // or rely on the user running the app as admin.
      // However, typical pattern is to spawn a shell with runas.
      
      // Since we can't easily trigger UAC from Dart `Process.run` without extra tools,
      // we will use PowerShell Start-Process with -Verb RunAs.

      final command = 'Start-Process "open_port.bat" -ArgumentList "$port" -Verb RunAs';
      
      await Process.run('powershell', ['-Command', command]);
      _log.info('Requested to open port $port');
    } catch (e) {
      _log.severe('Error opening port: $e');
      rethrow;
    }
  }

  Future<bool> isPortOpen(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final networkServiceProvider = Provider((ref) => NetworkService());
