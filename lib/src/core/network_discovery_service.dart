import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

/// Represents a discovered dental clinic server (dentist device)
class DiscoveredServer {
  final String id;
  final String name;
  final String ipAddress;
  final int port;
  final String clinicName;
  final String dentistName;
  final DateTime discoveredAt;
  final DateTime? lastSeen;

  DiscoveredServer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.clinicName,
    required this.dentistName,
    required this.discoveredAt,
    this.lastSeen,
  });

  factory DiscoveredServer.fromJson(Map<String, dynamic> json) {
    return DiscoveredServer(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ipAddress'],
      port: json['port'],
      clinicName: json['clinicName'],
      dentistName: json['dentistName'],
      discoveredAt: DateTime.parse(json['discoveredAt']),
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ipAddress': ipAddress,
      'port': port,
      'clinicName': clinicName,
      'dentistName': dentistName,
      'discoveredAt': discoveredAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '$clinicName ($dentistName) - $ipAddress:$port';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredServer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Service for discovering dental clinic servers on the local network
class NetworkDiscoveryService {
  static const int discoveryPort = 8888;
  static const String discoveryMessage = 'DENTAL_TID_DISCOVERY';
  static const String serverResponsePrefix = 'DENTAL_TID_SERVER:';
  static const Duration discoveryInterval = Duration(seconds: 5);
  static const Duration serverTimeout = Duration(seconds: 30);

  final Logger _logger = Logger('NetworkDiscoveryService');

  RawDatagramSocket? _discoverySocket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  final StreamController<List<DiscoveredServer>> _serversController =
      StreamController<List<DiscoveredServer>>.broadcast();

  final Map<String, DiscoveredServer> _discoveredServers = {};

  /// Stream of discovered servers
  Stream<List<DiscoveredServer>> get discoveredServers =>
      _serversController.stream;

  /// Get current list of discovered servers
  List<DiscoveredServer> get currentServers =>
      _discoveredServers.values.toList();

  /// Start server discovery (for client devices - assistants/receptionists)
  Future<void> startDiscovery() async {
    _logger.info('Starting network discovery...');

    try {
      // Create UDP socket for discovery
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _discoverySocket!.broadcastEnabled = true;

      _logger.info('Discovery socket bound to port ${_discoverySocket!.port}');

      // Listen for server responses
      _discoverySocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          _handleIncomingMessage();
        }
      });

      // Start periodic broadcast
      _broadcastTimer = Timer.periodic(discoveryInterval, (_) {
        _sendDiscoveryBroadcast();
      });

      // Start cleanup timer to remove stale servers
      _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _cleanupStaleServers();
      });

      // Send initial broadcast
      _sendDiscoveryBroadcast();

      _logger.info('Network discovery started successfully');
    } catch (e) {
      _logger.severe('Failed to start network discovery: $e');
      rethrow;
    }
  }

  /// Stop server discovery
  void stopDiscovery() {
    _logger.info('Stopping network discovery...');

    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _discoverySocket?.close();
    _discoverySocket = null;

    _discoveredServers.clear();
    _serversController.add([]);

    _logger.info('Network discovery stopped');
  }

  /// Start server broadcasting (for dentist devices)
  Future<void> startBroadcasting({
    required String serverId,
    required String clinicName,
    required String dentistName,
    int port = 8080,
  }) async {
    _logger.info('Starting server broadcasting for $clinicName...');

    try {
      // Create UDP socket for broadcasting
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
      );
      _discoverySocket!.broadcastEnabled = true;

      _logger.info('Broadcast socket bound to port $discoveryPort');

      // Listen for discovery requests
      _discoverySocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          _handleDiscoveryRequest(serverId, clinicName, dentistName, port);
        }
      });

      _logger.info('Server broadcasting started successfully for $clinicName');
    } catch (e) {
      _logger.severe('Failed to start server broadcasting: $e');
      rethrow;
    }
  }

  /// Stop server broadcasting
  void stopBroadcasting() {
    _logger.info('Stopping server broadcasting...');
    _discoverySocket?.close();
    _discoverySocket = null;
    _logger.info('Server broadcasting stopped');
  }

  /// Send discovery broadcast to find servers
  void _sendDiscoveryBroadcast() {
    if (_discoverySocket == null) return;

    try {
      final message = utf8.encode(discoveryMessage);
      _discoverySocket!.send(
        message,
        InternetAddress('255.255.255.255'), // Broadcast address
        discoveryPort,
      );

      _logger.fine('Sent discovery broadcast');
    } catch (e) {
      _logger.warning('Failed to send discovery broadcast: $e');
    }
  }

  /// Handle incoming messages
  void _handleIncomingMessage() {
    if (_discoverySocket == null) return;

    try {
      final datagram = _discoverySocket!.receive();
      if (datagram == null) return;

      final message = utf8.decode(datagram.data);
      _logger.fine(
        'Received message from ${datagram.address.address}:${datagram.port}: $message',
      );

      if (message.startsWith(serverResponsePrefix)) {
        final serverInfo = message.substring(serverResponsePrefix.length);
        final serverData = json.decode(serverInfo);

        final server = DiscoveredServer.fromJson(serverData);
        _addOrUpdateServer(server);
      }
    } catch (e) {
      _logger.warning('Error handling incoming message: $e');
    }
  }

  /// Handle discovery request from client
  void _handleDiscoveryRequest(
    String serverId,
    String clinicName,
    String dentistName,
    int port,
  ) async {
    if (_discoverySocket == null) return;

    try {
      final datagram = _discoverySocket!.receive();
      if (datagram == null) return;

      final message = utf8.decode(datagram.data);
      if (message != discoveryMessage) return;

      _logger.fine(
        'Received discovery request from ${datagram.address.address}:${datagram.port}',
      );

      // Send server information back to client
      final serverInfo = {
        'id': serverId,
        'name': 'DentalTid Server',
        'ipAddress': await _getLocalIpAddress(),
        'port': port,
        'clinicName': clinicName,
        'dentistName': dentistName,
        'discoveredAt': DateTime.now().toIso8601String(),
      };

      final responseMessage = serverResponsePrefix + json.encode(serverInfo);
      final responseData = utf8.encode(responseMessage);

      _discoverySocket!.send(responseData, datagram.address, datagram.port);

      _logger.fine(
        'Sent server response to ${datagram.address.address}:${datagram.port}',
      );
    } catch (e) {
      _logger.warning('Error handling discovery request: $e');
    }
  }

  /// Add or update discovered server
  void _addOrUpdateServer(DiscoveredServer server) {
    final existingServer = _discoveredServers[server.id];

    if (existingServer != null) {
      // Update last seen time
      _discoveredServers[server.id] = existingServer.copyWith(
        lastSeen: DateTime.now(),
      );
    } else {
      // Add new server
      _discoveredServers[server.id] = server.copyWith(lastSeen: DateTime.now());
      _logger.info('Discovered new server: $server');
    }

    _serversController.add(currentServers);
  }

  /// Clean up stale servers
  void _cleanupStaleServers() {
    final now = DateTime.now();
    final staleServers = <String>[];

    _discoveredServers.forEach((id, server) {
      if (server.lastSeen != null &&
          now.difference(server.lastSeen!) > serverTimeout) {
        staleServers.add(id);
      }
    });

    for (final id in staleServers) {
      _discoveredServers.remove(id);
      _logger.info('Removed stale server: $id');
    }

    if (staleServers.isNotEmpty) {
      _serversController.add(currentServers);
    }
  }

  /// Get local IP address
  Future<String> _getLocalIpAddress() async {
    try {
      // Get network interfaces
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Return first non-loopback IPv4 address
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to get local IP address: $e');
    }

    return '127.0.0.1'; // Fallback
  }

  /// Dispose of resources
  void dispose() {
    stopDiscovery();
    stopBroadcasting();
    _serversController.close();
  }
}

extension on DiscoveredServer {
  DiscoveredServer copyWith({
    String? id,
    String? name,
    String? ipAddress,
    int? port,
    String? clinicName,
    String? dentistName,
    DateTime? discoveredAt,
    DateTime? lastSeen,
  }) {
    return DiscoveredServer(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      clinicName: clinicName ?? this.clinicName,
      dentistName: dentistName ?? this.dentistName,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
