import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/network_discovery_service.dart';
import 'package:dentaltid/src/core/sync_manager.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/app_colors.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

class ConnectionSettingsScreen extends ConsumerStatefulWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  ConsumerState<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState
    extends ConsumerState<ConnectionSettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '8080',
  );
  final TextEditingController _serverPortController = TextEditingController(
    text: '8080',
  );
  bool _isConnecting = false;
  String? _statusMessage;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Default submask usually 192.168.1.
    _ipController.text = '192.168.1.';
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _serverPortController.dispose();
    super.dispose();
  }

  Future<void> _toggleServer() async {
      final syncManager = ref.read(syncManagerProvider);
      if (syncManager.isServerRunning) {
          await syncManager.stopServer();
      } else {
          final port = int.tryParse(_serverPortController.text) ?? 8080;
          await syncManager.startServer(port);
      }
      setState(() {}); // Refresh UI
  }

  Future<void> _manualConnect() async {
    final l10n = AppLocalizations.of(context)!;
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();
    final port = int.tryParse(portStr);

    if (ip.isEmpty || port == null) {
      setState(() {
        _statusMessage = l10n.invalidIpOrPort;
        _statusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = l10n.connecting;
      _statusColor = Colors.orange;
    });

    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) {
         throw Exception('User profile not loaded');
      }

      // Create a "Dummy" discovered server object to re-use existing logic
      final manualServer = DiscoveredServer(
        id: 'manual',
        name: 'Manual Server',
        ipAddress: ip,
        port: port,
        clinicName: 'Manual Connection',
        dentistName: 'Server',
        discoveredAt: DateTime.now(),
      );

      final syncManager = ref.read(syncManagerProvider);
      await syncManager.initializeAsClient(
        server: manualServer,
        userProfile: userProfile,
      );

      setState(() {
        _statusMessage = l10n.connectedSync;
        _statusColor = Colors.green;
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Connection Failed: $e';
        _statusColor = Colors.red;
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProfile = ref.watch(userProfileProvider).value;
    final isDentist = userProfile?.role == UserRole.dentist;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.connectionSettings)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.networkConnection,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDentist
                    ? l10n.serverDeviceNotice
                    : l10n.clientDeviceNotice,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (isDentist) _buildServerInfo() else _buildClientControls(),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              if (!isDentist) ...[
                  Text(
                    l10n.connectionStatus,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                   const SizedBox(height: 8),
                  _buildStatusStream(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerInfo() {
    final l10n = AppLocalizations.of(context)!;
    final syncManager = ref.watch(syncManagerProvider);
    final isRunning = syncManager.isServerRunning;

    return Column(
      children: [
        // Status Card
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(Icons.wifi_tethering, size: 48, color: isRunning ? Colors.green : Colors.grey),
                      const SizedBox(width: 16),
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                             Text(
                                 isRunning ? l10n.serverRunning : l10n.serverStopped, 
                                 style: TextStyle(
                                     fontSize: 20, 
                                     fontWeight: FontWeight.bold,
                                     color: isRunning ? Colors.green : Colors.red
                                 )
                             ),
                             if (isRunning) Text('Port: ${_serverPortController.text}'),
                         ],
                      )
                   ],
                ),
                const SizedBox(height: 24),
                
                // IP Address List
                FutureBuilder<List<String>>(
                  future: _getLocalIps(),
                  builder: (context, snapshot) {
                     final ips = snapshot.data ?? ['Loading...'];
                     return Column(
                        children: [
                             Text(l10n.possibleIpAddresses, style: const TextStyle(fontWeight: FontWeight.bold)),
                             ...ips.map((ip) => SelectableText(ip, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary))),
                        ],
                     );
                  }
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Controls
                Row(
                   children: [
                       Expanded(
                           child: TextField(
                               controller: _serverPortController,
                               enabled: !isRunning,
                               decoration: InputDecoration(
                                   labelText: l10n.port,
                                   border: const OutlineInputBorder(),
                               ),
                               keyboardType: TextInputType.number,
                           ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                           flex: 2,
                           child: SizedBox(
                               height: 56,
                               child: ElevatedButton.icon(
                                   onPressed: _toggleServer,
                                   style: ElevatedButton.styleFrom(
                                       backgroundColor: isRunning ? Colors.red : Colors.green,
                                       foregroundColor: Colors.white,
                                   ),
                                   icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                                   label: Text(isRunning ? l10n.stopServer : l10n.startServer),
                               ),
                           ),
                       ),
                   ],
                ),
                
                const SizedBox(height: 16),
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                   child: Row(children: [
                       const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                       const SizedBox(width: 8),
                       Expanded(child: Text(l10n.firewallWarning, style: const TextStyle(fontSize: 12))),
                   ]),
                )
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Logs Section
        Card(
            elevation: 2,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text(l10n.serverLogs, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                        ),
                        const Divider(),
                        Container(
                            height: 200,
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                            child: StreamBuilder<List<String>>(
                                stream: syncManager.logs,
                                builder: (context, snapshot) {
                                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                        return const Center(child: Text('No logs yet.', style: TextStyle(color: Colors.grey)));
                                    }
                                    final logs = snapshot.data!;
                                    
                                    return Stack(
                                        children: [
                                            ListView.builder(
                                                padding: const EdgeInsets.all(8),
                                                itemCount: logs.length,
                                                reverse: true, // Newest logs at bottom
                                                itemBuilder: (context, index) => Text(logs[index], style: const TextStyle(fontSize: 12, fontFamily: 'Courier')),
                                            ),
                                            Positioned(
                                                right: 0, 
                                                top: 0,
                                                child: IconButton(
                                                    icon: const Icon(Icons.copy, size: 16),
                                                    onPressed: () {
                                                        Clipboard.setData(ClipboardData(text: logs.join('\n')));
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copyLogsSuccess)));
                                                    },
                                                ),
                                            )
                                        ],
                                    );
                                },
                            ),
                        ),
                    ],
                ),
            ),
        ),
      ],
    );
  }

  Widget _buildClientControls() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.manualConnection,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: l10n.serverIpAddress,
                hintText: 'e.g., 192.168.1.15',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.computer),
                helperText: 'Enter the IP displayed on the Dentist\'s device',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isConnecting ? null : _manualConnect,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link),
                label: Text(
                    _isConnecting ? l10n.connecting : l10n.connectToServer),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusColor),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                      color: _statusColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStream() {
    final l10n = AppLocalizations.of(context)!;
    final syncStatusStream = ref.watch(syncManagerProvider).syncStatus;

    return StreamBuilder<Map<String, dynamic>>(
      stream: syncStatusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(l10n.readyToConnect,
              style: const TextStyle(color: Colors.grey));
        }
        final data = snapshot.data!;
        final type = data['type'];
        final msg = data['message'] ?? type;

        // Highlight specific statuses
        Color color = Colors.black87;
        if (type == 'sync_status') {
          if (data['status'] == 'syncing') color = Colors.orange;
          if (data['status'] == 'synced') color = Colors.green;
          if (data['status'] == 'error') color = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('$msg', style: TextStyle(color: color))),
            ],
          ),
        );
      },
    );
  }

  // ... (client controls remain same)

  Future<List<String>> _getLocalIps() async {
    List<String> ips = [];
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
             ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    return ips.isNotEmpty ? ips : ['Unknown IP'];
  }
}
