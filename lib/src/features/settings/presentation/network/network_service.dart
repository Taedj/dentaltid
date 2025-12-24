import 'dart:io';
import 'package:path/path.dart' as path;
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
    if (!Platform.isWindows) {
      _log.info('Firewall port opening is only supported on Windows.');
      return;
    }

    final batPath = path.join(Directory.current.path, 'fix_network.bat');
    
    try {
      _log.info('Requesting elevated firewall setup for port $port...');

      // We use PowerShell to launch the .bat file with 'RunAs' verb for elevation.
      // Using -Verb RunAs is the standard way to trigger the UAC prompt.
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-Command',
        'Start-Process',
        'cmd.exe',
        '-ArgumentList',
        "\"/c `\"$batPath`\"\"",
        '-Verb',
        'RunAs',
      ]);

      if (result.exitCode != 0) {
        _log.severe('PowerShell elevation request failed: ${result.stderr}');
        throw Exception('Failed to request administrative rights. Please run fix_network.bat as Administrator manually.');
      }
      
      _log.info('Elevation prompt shown. Please accept it to open the port.');
    } catch (e) {
      _log.severe('Error opening port: $e');
      rethrow;
    }
  }

  Future<bool> isPortOpen(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final networkServiceProvider = Provider((ref) => NetworkService());
