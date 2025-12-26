import 'dart:async';
import 'package:dentaltid/src/core/log_service.dart';
import 'package:dentaltid/src/core/network/network_scanner_service.dart';
import 'package:dentaltid/src/core/network/network_status_provider.dart';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart';
import 'package:dentaltid/src/features/settings/presentation/network/network_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

class NetworkConfigDialog extends ConsumerStatefulWidget {
  final UserType userType;
  const NetworkConfigDialog({super.key, required this.userType});

  @override
  ConsumerState<NetworkConfigDialog> createState() =>
      _NetworkConfigDialogState();
}

class _NetworkConfigDialogState extends ConsumerState<NetworkConfigDialog> {
  bool _isLoading = true;
  List<String> _localIps = [];
  String? _selectedIp;

  final _serverPortController = TextEditingController(text: '8080');
  List<String> _serverLogs = [];
  StreamSubscription? _logSubscription;
  final ScrollController _logScrollController = ScrollController();

  final _clientIpController = TextEditingController();
  final _clientPortController = TextEditingController(text: '8080');

  bool _autoStartServer = false;
  bool _autoConnectClient = false;

  @override
  void initState() {
    super.initState();
    _serverLogs = List.from(LogService.instance.history);
    _logSubscription = LogService.instance.onLog.listen((log) {
      if (mounted) {
        setState(() {
          _serverLogs.add(log);
          if (_serverLogs.length > 200) _serverLogs.removeAt(0);
        });
        _scrollToBottom();
      }
    });
    _init();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _serverPortController.dispose();
    _clientIpController.dispose();
    _clientPortController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _init() async {
    final settings = SettingsService.instance;
    await settings.init();
    final ips = await ref.read(networkServiceProvider).getLocalIpAddresses();

    if (mounted) {
      setState(() {
        _localIps = ips;
        if (ips.isNotEmpty) {
          _selectedIp = ips.first;
        }
        _autoStartServer = settings.getBool('autoStartServer') ?? false;
        _autoConnectClient = settings.getBool('autoConnectClient') ?? false;
        _clientIpController.text = settings.getString('autoConnectIp') ?? '';
        _clientPortController.text =
            settings.getString('autoConnectPort') ?? '8080';
        _serverPortController.text = settings.getString('serverPort') ?? '8080';

        _isLoading = false;
      });
    }
  }

  Future<void> _onAutoStartServerChanged(bool value) async {
    final settings = SettingsService.instance;
    await settings.setBool('autoStartServer', value);
    if (value) {
      await settings.setString('serverPort', _serverPortController.text);
    }
    setState(() => _autoStartServer = value);
  }

  Future<void> _onAutoConnectClientChanged(bool value) async {
    final settings = SettingsService.instance;
    await settings.setBool('autoConnectClient', value);
    if (value) {
      await settings.setString('autoConnectIp', _clientIpController.text);
      await settings.setString('autoConnectPort', _clientPortController.text);
    }
    setState(() => _autoConnectClient = value);
  }

  void _addLog(String message) {
    // We now use global Logger, but keeping this for explicit UI-only notes if any.
    Logger('NetworkDialog').info(message);
  }

  Future<void> _openPort() async {
    final port = int.tryParse(
      widget.userType == UserType.dentist
          ? _serverPortController.text
          : _clientPortController.text,
    );
    if (port == null) return;

    _addLog('Requesting to open firewall port $port...');
    try {
      await ref.read(networkServiceProvider).openFirewallPort(port);
      _addLog('Firewall rule script executed.');
    } catch (e) {
      _addLog('Error opening port: $e');
    }
  }

  Future<void> _checkPort() async {
    final port = int.tryParse(
      widget.userType == UserType.dentist
          ? _serverPortController.text
          : _clientPortController.text,
    );
    final ip = widget.userType == UserType.dentist
        ? _selectedIp
        : _clientIpController.text;
    if (port == null || ip == null || ip.isEmpty) return;

    _addLog('Checking port $port on $ip...');
    final isOpen = await ref.read(networkServiceProvider).isPortOpen(ip, port);
    _addLog(isOpen ? 'Port $port is OPEN.' : 'Port $port is CLOSED.');
  }

  bool _isStartingServer = false;

  Future<void> _toggleServer(ConnectionStatus currentStatus) async {
    if (_isStartingServer) return;

    if (currentStatus == ConnectionStatus.serverRunning) {
      await ref.read(syncServerProvider).stop();
      _addLog('Server stopped.');
    } else {
      final port = int.tryParse(_serverPortController.text);
      if (port == null || _selectedIp == null) {
        _addLog('Error: Invalid port or no IP address selected.');
        return;
      }

      setState(() => _isStartingServer = true);
      try {
        await ref.read(syncServerProvider).start(port);
        _addLog('Server started on $_selectedIp:$port');
      } catch (e) {
        _addLog('Failed to start server: $e');
        ref
            .read(networkStatusProvider.notifier)
            .setStatus(ConnectionStatus.error);
      } finally {
        if (mounted) setState(() => _isStartingServer = false);
      }
    }
  }

  Future<void> _scanAndConnect() async {
    _addLog('Scanning for servers...');

    final port = int.tryParse(_clientPortController.text);
    if (port == null) {
      _addLog('Invalid port for scanning.');
      return;
    }

    final foundServers = await ref
        .read(networkScannerProvider)
        .scanForServers(port: port);

    if (!mounted) return;

    if (foundServers.isEmpty) {
      _addLog('No servers found on the network.');
      return;
    }

    final selectedServer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Server'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: foundServers.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.dns),
                title: Text(foundServers[index]),
                onTap: () => Navigator.of(context).pop(foundServers[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedServer != null) {
      _addLog('Server selected: $selectedServer. Please press CONNECT.');
      setState(() {
        _clientIpController.text = selectedServer;
      });
    }
  }

  Future<void> _manualConnect(ConnectionStatus currentStatus) async {
    if (currentStatus == ConnectionStatus.synced ||
        currentStatus == ConnectionStatus.syncing ||
        currentStatus == ConnectionStatus.connecting) {
      await ref.read(syncClientProvider).disconnect();
      _addLog('Disconnected.');
      return;
    }

    final ip = _clientIpController.text;
    final portStr = _clientPortController.text;
    final port = int.tryParse(portStr);
    if (ip.isEmpty || port == null) return;

    _addLog('Connecting to $ip:$port...');
    try {
      await ref.read(syncClientProvider).connect(ip, port);
    } catch (e) {
      _addLog('Connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDentist = widget.userType == UserType.dentist;
    final networkStatus = ref.watch(networkStatusProvider);

    ref.listen(networkStatusProvider, (previous, status) {
      if (previous == status) return;

      final statusText = status.toString().split('.').last;
      if (status == ConnectionStatus.error) {
        _addLog('ERROR state detected.');
      } else if (status == ConnectionStatus.handshakeAccepted) {
        _addLog('Handshake accepted. Waiting for data...');
      } else if (status == ConnectionStatus.synced) {
        _addLog('Sync complete. Ready.');
      } else if (status == ConnectionStatus.serverRunning) {
        _addLog('SERVER ONLINE');
      } else if (status == ConnectionStatus.disconnected) {
        _addLog('DISCONNECTED');
      } else {
        _addLog('Status changed: ${statusText.toUpperCase()}');
      }
    });

    return AlertDialog(
      title: Row(
        children: [
          Icon(isDentist ? Icons.dns : Icons.lan, color: Colors.blue),
          const SizedBox(width: 10),
          Text(
            isDentist
                ? 'Server Configuration (Dentist)'
                : 'Client Configuration (Staff)',
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (isDentist) _buildServerStatusHeader(networkStatus),
                  const SizedBox(height: 20),

                  Expanded(
                    child: isDentist
                        ? _buildServerView(networkStatus)
                        : _buildClientView(networkStatus),
                  ),

                  const Divider(),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'System Logs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _logScrollController,
                          itemCount: _serverLogs.length,
                          itemBuilder: (context, index) => Text(
                            _serverLogs[index],
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'Courier',
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: Colors.white54,
                              size: 16,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _serverLogs.join('\n')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        if (networkStatus == ConnectionStatus.serverRunning ||
            networkStatus == ConnectionStatus.synced)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Minimize & Keep Running'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildServerStatusHeader(ConnectionStatus status) {
    final bool isServerRunning = status == ConnectionStatus.serverRunning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withAlpha(75)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Select Local IP Address',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      onPressed: _init,
                      tooltip: 'Refresh IP List',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (_localIps.isEmpty)
                  const Text(
                    'No networks found',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                else
                  DropdownButton<String>(
                    value: _selectedIp,
                    isExpanded: true,
                    items: _localIps
                        .map(
                          (ip) => DropdownMenuItem(
                            value: ip,
                            child: Text(
                              ip,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (ip) => setState(() => _selectedIp = ip),
                    underline: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isServerRunning ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isServerRunning ? 'ONLINE' : 'OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerView(ConnectionStatus status) {
    final bool isServerRunning = status == ConnectionStatus.serverRunning;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _serverPortController,
                enabled: !isServerRunning,
                decoration: const InputDecoration(
                  labelText: 'Listening Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _checkPort,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check Port'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _openPort,
              icon: const Icon(Icons.security),
              label: const Text('Open Port (Admin)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _toggleServer(status),
            icon: Icon(isServerRunning ? Icons.stop : Icons.play_arrow),
            label: Text(isServerRunning ? 'STOP SERVER' : 'START SERVER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isServerRunning ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Start the server to allow staff members to connect and sync data.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: const Text('Auto-start Server on App Launch'),
          value: _autoStartServer,
          onChanged: isServerRunning ? null : _onAutoStartServerChanged,
        ),
      ],
    );
  }

  Widget _buildClientView(ConnectionStatus status) {
    final bool isConnecting =
        status == ConnectionStatus.connecting ||
        status == ConnectionStatus.handshakeAccepted ||
        status == ConnectionStatus.syncing;
    final bool isConnected = status == ConnectionStatus.synced;

    if (isConnecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              status == ConnectionStatus.syncing
                  ? 'Syncing Database...'
                  : (status == ConnectionStatus.handshakeAccepted
                        ? 'Waiting for database export...'
                        : 'Connecting to server...'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _scanAndConnect,
            icon: const Icon(Icons.radar),
            label: const Text('AUTO SCAN FOR SERVER'),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('OR MANUAL'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _clientIpController,
                enabled: !isConnected,
                decoration: const InputDecoration(
                  labelText: 'Server IP',
                  border: OutlineInputBorder(),
                  hintText: '192.168.1.X',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _clientPortController,
                enabled: !isConnected,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _manualConnect(status),
                icon: Icon(isConnected ? Icons.link_off : Icons.link),
                label: Text(isConnected ? 'DISCONNECT' : 'CONNECT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? Colors.redAccent
                      : Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Check Port',
              onPressed: isConnected ? null : _checkPort,
            ),
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: 'Open Port in Firewall',
              onPressed: isConnected ? null : _openPort,
              color: Colors.orange,
            ),
          ],
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: const Text('Auto-connect on App Launch'),
          value: _autoConnectClient,
          onChanged: isConnected ? null : _onAutoConnectClientChanged,
        ),
      ],
    );
  }
}
