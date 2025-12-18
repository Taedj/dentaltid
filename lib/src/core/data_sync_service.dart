import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/network_discovery_service.dart';

/// Types of data that can be synchronized
enum SyncDataType { patients, appointments, transactions, inventory, settings }

/// Represents a data synchronization message
class SyncMessage {
  final String id;
  final SyncDataType type;
  final String operation; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String deviceId;
  final String userId;

  SyncMessage({
    required this.id,
    required this.type,
    required this.operation,
    required this.data,
    required this.timestamp,
    required this.deviceId,
    required this.userId,
  });

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      id: json['id'],
      type: SyncDataType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SyncDataType.patients,
      ),
      operation: json['operation'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      deviceId: json['deviceId'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'operation': operation,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'userId': userId,
    };
  }

  @override
  String toString() {
    return '$operation $type: ${data['id'] ?? 'unknown'} by $userId';
  }
}

/// Service for synchronizing data between dentist and staff devices over LAN
class DataSyncService {
  static const int syncPort = 8080;
  static const String syncProtocol = 'dentaltid-sync';

  final Logger _logger = Logger('DataSyncService');

  HttpServer? _server;
  WebSocket? _clientConnection;
  final Map<String, WebSocket> _connectedClients = {};

  final StreamController<SyncMessage> _incomingMessagesController =
      StreamController<SyncMessage>.broadcast();

  /// Stream of incoming synchronization messages
  Stream<SyncMessage> get incomingMessages =>
      _incomingMessagesController.stream;

  /// Get number of connected clients (for dentist server)
  int get connectedClientsCount => _connectedClients.length;

  /// Check if connected to a server (for client devices)
  bool get isConnected => _clientConnection != null;

  /// Start synchronization server (for dentist devices)
  Future<void> startServer({
    required String serverId,
    required UserProfile dentistProfile,
    int port = syncPort,
  }) async {
    _logger.info(
      'Starting data sync server for dentist: ${dentistProfile.dentistName}',
    );

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _logger.info('Sync server bound to port $port');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final clientId = request.headers.value('client-id') ?? 'unknown';
          _logger.info('Client $clientId attempting to connect');

          final socket = await WebSocketTransformer.upgrade(request);
          _connectedClients[clientId] = socket;

          _logger.info(
            'Client $clientId connected. Total clients: $connectedClientsCount',
          );

          // Handle incoming messages from this client
          socket.listen(
            (message) => _handleIncomingMessage(message, clientId),
            onDone: () {
              _logger.info('Client $clientId disconnected');
              _connectedClients.remove(clientId);
            },
            onError: (error) {
              _logger.warning('Error with client $clientId: $error');
              _connectedClients.remove(clientId);
            },
          );

          // Send welcome message
          _sendToClient(socket, {
            'type': 'welcome',
            'serverId': serverId,
            'dentistProfile': dentistProfile.toJson(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('WebSocket connections only')
            ..close();
        }
      });

      _logger.info('Data sync server started successfully');
    } catch (e) {
      _logger.severe('Failed to start data sync server: $e');
      rethrow;
    }
  }

  /// Stop synchronization server
  void stopServer() {
    _logger.info('Stopping data sync server...');

    for (final socket in _connectedClients.values) {
      socket.close();
    }
    _connectedClients.clear();

    _server?.close();
    _server = null;

    _logger.info('Data sync server stopped');
  }

  /// Connect to synchronization server (for client devices)
  Future<void> connectToServer({
    required DiscoveredServer server,
    required String clientId,
    required UserProfile userProfile,
  }) async {
    _logger.info(
      'Connecting to sync server: ${server.ipAddress}:${server.port}',
    );

    try {
      final uri = Uri.parse('ws://${server.ipAddress}:${server.port}');
      _clientConnection = await WebSocket.connect(
        uri.toString(),
        headers: {
          'client-id': clientId,
          'user-profile': json.encode(userProfile.toJson()),
        },
      );

      _logger.info('Connected to sync server successfully');

      // Handle incoming messages from server
      _clientConnection!.listen(
        (message) => _handleServerMessage(message),
        onDone: () {
          _logger.info('Disconnected from sync server');
          _clientConnection = null;
        },
        onError: (error) {
          _logger.warning('Error with sync server connection: $error');
          _clientConnection = null;
        },
      );
    } catch (e) {
      _logger.severe('Failed to connect to sync server: $e');
      _clientConnection = null;
      rethrow;
    }
  }

  /// Disconnect from server
  void disconnectFromServer() {
    _logger.info('Disconnecting from sync server...');
    _clientConnection?.close();
    _clientConnection = null;
    _logger.info('Disconnected from sync server');
  }

  /// Send synchronization message to all connected clients (server mode)
  Future<void> broadcastToClients(SyncMessage message) async {
    if (_connectedClients.isEmpty) {
      _logger.fine('No clients connected, message not sent: $message');
      return;
    }

    final messageData = {'type': 'sync', 'message': message.toJson()};

    for (final entry in _connectedClients.entries) {
      try {
        _sendToClient(entry.value, messageData);
        _logger.fine('Sent message to client ${entry.key}: $message');
      } catch (e) {
        _logger.warning('Failed to send message to client ${entry.key}: $e');
      }
    }
  }

  /// Send synchronization message to server (client mode)
  Future<void> sendToServer(SyncMessage message) async {
    if (_clientConnection == null) {
      _logger.warning('Not connected to server, cannot send message: $message');
      return;
    }

    final messageData = {'type': 'sync', 'message': message.toJson()};

    try {
      _sendToClient(_clientConnection!, messageData);
      _logger.fine('Sent message to server: $message');
    } catch (e) {
      _logger.warning('Failed to send message to server: $e');
      // Try to reconnect
      _clientConnection = null;
    }
  }

  /// Send data to a specific client WebSocket
  void _sendToClient(WebSocket socket, Map<String, dynamic> data) {
    if (socket.readyState == WebSocket.open) {
      socket.add(json.encode(data));
    }
  }

  /// Handle incoming message from a client (server mode)
  void _handleIncomingMessage(dynamic message, String clientId) {
    try {
      final data = json.decode(message as String);
      final messageType = data['type'];

      switch (messageType) {
        case 'sync':
          final syncMessage = SyncMessage.fromJson(data['message']);
          _logger.fine(
            'Received sync message from client $clientId: $syncMessage',
          );
          _incomingMessagesController.add(syncMessage);
          break;

        case 'ping':
          _sendToClient(_connectedClients[clientId]!, {'type': 'pong'});
          break;

        default:
          _logger.warning(
            'Unknown message type from client $clientId: $messageType',
          );
      }
    } catch (e) {
      _logger.warning('Error handling message from client $clientId: $e');
    }
  }

  /// Handle incoming message from server (client mode)
  void _handleServerMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      final messageType = data['type'];

      switch (messageType) {
        case 'welcome':
          _logger.info(
            'Received welcome from server: ${data['dentistProfile']['dentistName']}',
          );
          break;

        case 'sync':
          final syncMessage = SyncMessage.fromJson(data['message']);
          _logger.fine('Received sync message from server: $syncMessage');
          _incomingMessagesController.add(syncMessage);
          break;

        case 'pong':
          // Handle ping response
          break;

        default:
          _logger.warning('Unknown message type from server: $messageType');
      }
    } catch (e) {
      _logger.warning('Error handling message from server: $e');
    }
  }

  /// Send ping to keep connection alive
  void ping() {
    if (_clientConnection != null) {
      _sendToClient(_clientConnection!, {'type': 'ping'});
    }
  }

  /// Dispose of resources
  void dispose() {
    stopServer();
    disconnectFromServer();
    _incomingMessagesController.close();
  }
}
