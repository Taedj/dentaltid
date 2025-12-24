import 'dart:async';
import 'dart:io';

import 'package:dentaltid/src/features/settings/presentation/network/network_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class NetworkScannerService {
  final Ref _ref;
  final Logger _log = Logger('NetworkScanner');

  NetworkScannerService(this._ref);

  Future<List<String>> scanForServers({
    required int port,
    Duration timeout = const Duration(milliseconds: 200),
  }) async {
    final localIps = await _ref
        .read(networkServiceProvider)
        .getLocalIpAddresses();
    if (localIps.isEmpty) {
      _log.warning('No local IP address found. Cannot scan.');
      return [];
    }

    // Use the first local IP to determine the subnet
    final localIp = localIps.first;
    final subnet = localIp.substring(0, localIp.lastIndexOf('.') + 1);
    _log.info('Scanning subnet $subnet* on port $port...');

    final futures = <Future<String?>>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet$i';
      futures.add(_pingServer(ip, port, timeout));
    }

    final results = await Future.wait(futures);
    final foundServers = results.whereType<String>().toList();

    _log.info('Scan complete. Found ${foundServers.length} potential servers.');
    return foundServers;
  }

  Future<String?> _pingServer(String ip, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      _log.info('Found server at $ip:$port');
      return ip;
    } catch (e) {
      // This is expected for non-server IPs, so we don't log it as an error.
      return null;
    }
  }
}

final networkScannerProvider = Provider((ref) => NetworkScannerService(ref));
