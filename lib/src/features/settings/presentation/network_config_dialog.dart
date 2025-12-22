import 'dart:async';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/features/security/presentation/auth_screen.dart'; 
import 'package:dentaltid/src/features/settings/presentation/network/network_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkConfigDialog extends ConsumerStatefulWidget {
  final UserType userType;
  const NetworkConfigDialog({super.key, required this.userType});

  @override
  ConsumerState<NetworkConfigDialog> createState() => _NetworkConfigDialogState();
}

class _NetworkConfigDialogState extends ConsumerState<NetworkConfigDialog> {
  bool _isLoading = true;
  List<String> _localIps = [];
  String? _selectedIp;
  
  final _serverPortController = TextEditingController(text: '8080');
  bool _isServerRunning = false;
  final List<String> _serverLogs = [];
  final ScrollController _logScrollController = ScrollController();

  final _clientIpController = TextEditingController();
  final _clientPortController = TextEditingController(text: '8080');
  bool _isConnected = false;

  bool _autoStartServer = false;
  bool _autoConnectClient = false;
  
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _serverPortController.dispose();
    _clientIpController.dispose();
    _clientPortController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final ips = await ref.read(networkServiceProvider).getLocalIpAddresses();

    if (mounted) {
      setState(() {
        _localIps = ips;
        if (ips.isNotEmpty) {
          _selectedIp = ips.first;
        }
        _autoStartServer = prefs.getBool('autoStartServer') ?? false;
        _autoConnectClient = prefs.getBool('autoConnectClient') ?? false;
        _clientIpController.text = prefs.getString('autoConnectIp') ?? '';
        _clientPortController.text = prefs.getString('autoConnectPort') ?? '8080';
        _serverPortController.text = prefs.getString('serverPort') ?? '8080';
        
        _isLoading = false;
      });
    }
  }

  Future<void> _onAutoStartServerChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoStartServer', value);
    if (value) {
      await prefs.setString('serverPort', _serverPortController.text);
    }
    setState(() => _autoStartServer = value);
    _addLog('Auto-start server ${value ? 'enabled' : 'disabled'}.');
  }

  Future<void> _onAutoConnectClientChanged(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoConnectClient', value);
    if (value) {
      await prefs.setString('autoConnectIp', _clientIpController.text);
      await prefs.setString('autoConnectPort', _clientPortController.text);
    }
    setState(() => _autoConnectClient = value);
    _addLog('Auto-connect client ${value ? 'enabled' : 'disabled'}.');
  }

  void _addLog(String message) {
    setState(() {
      _serverLogs.add('[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] $message');
    });
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

  Future<void> _openPort() async {
    final port = int.tryParse(widget.userType == UserType.dentist ? _serverPortController.text : _clientPortController.text);
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
     final port = int.tryParse(widget.userType == UserType.dentist ? _serverPortController.text : _clientPortController.text);
     final ip = widget.userType == UserType.dentist ? _selectedIp : _clientIpController.text;
     if (port == null || ip == null || ip.isEmpty) return; 
     
     _addLog('Checking port $port on $ip...');
     final isOpen = await ref.read(networkServiceProvider).isPortOpen(ip, port);
     _addLog(isOpen ? 'Port $port is OPEN.' : 'Port $port is CLOSED.');
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
        await ref.read(syncServerProvider).stop();
        _addLog('Server stopped.');
        setState(() => _isServerRunning = false);
    } else {
        final port = int.tryParse(_serverPortController.text);
        if (port == null || _selectedIp == null) {
            _addLog('Error: Invalid port or no IP address selected.');
            return;
        }
        try {
            await ref.read(syncServerProvider).start(port);
            _addLog('Server started on $_selectedIp:$port');
            setState(() => _isServerRunning = true);
        } catch (e) {
            _addLog('Failed to start server: $e');
        }
    }
  }

  Future<void> _autoConnect() async {
      _addLog('Scanning for servers...');
      await Future.delayed(const Duration(seconds: 1));
      _addLog('No servers found (Scan not implemented).');
  }

  Future<void> _manualConnect() async {
      if (_isConnected) {
          await ref.read(syncClientProvider).disconnect();
          _addLog('Disconnected.');
          setState(() => _isConnected = false);
          return;
      }

      final ip = _clientIpController.text;
      final portStr = _clientPortController.text;
      final port = int.tryParse(portStr);
      if (ip.isEmpty || port == null) return; 
      
      _addLog('Connecting to $ip:$port...');
      try {
        await ref.read(syncClientProvider).connect(ip, port);
        _addLog('Connection successful! Waiting for initial sync...');
        setState(() => _isConnected = true);
      } catch (e) {
        _addLog('Connection failed: $e');
      }
  }

  @override
  Widget build(BuildContext context) {
    final isDentist = widget.userType == UserType.dentist;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isDentist ? Icons.dns : Icons.lan, color: Colors.blue),
          const SizedBox(width: 10),
          Text(isDentist ? 'Server Configuration (Dentist)' : 'Client Configuration (Staff)'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                    if (isDentist)
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    Expanded(
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                              const Text('Select Local IP Address', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              if (_localIps.isEmpty)
                                                const Text('No networks found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                                              else
                                                DropdownButton<String>(
                                                    value: _selectedIp,
                                                    isExpanded: true,
                                                    items: _localIps.map((ip) => DropdownMenuItem(value: ip, child: Text(ip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))).toList(),
                                                    onChanged: (ip) => setState(() => _selectedIp = ip),
                                                    underline: const SizedBox.shrink(),
                                                ),
                                          ],
                                      ),
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                            color: _isServerRunning ? Colors.green : Colors.red,
                                            borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                            _isServerRunning ? 'ONLINE' : 'OFFLINE',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    const SizedBox(height: 20),
                    
                    Expanded(
                        child: isDentist ? _buildServerView() : _buildClientView(),
                    ),
                    
                    const Divider(),
                    
                    const Align(alignment: Alignment.centerLeft, child: Text('System Logs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
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
                                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 11),
                                    ),
                                ),
                                Positioned(
                                    right: 0, top: 0,
                                    child: IconButton(
                                        icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
                                        onPressed: () {
                                            Clipboard.setData(ClipboardData(text: _serverLogs.join('\n')));
                                        },
                                    ),
                                )
                            ],
                        ),
                    ),
                ],
            ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildServerView() {
      return Column(
          children: [
              Row(
                  children: [
                      Expanded(
                          child: TextFormField(
                              controller: _serverPortController,
                              decoration: const InputDecoration(labelText: 'Listening Port', border: OutlineInputBorder()),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      ),
                  ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                      onPressed: _toggleServer,
                      icon: Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_isServerRunning ? 'STOP SERVER' : 'START SERVER'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _isServerRunning ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                      ),
                  ),
              ),
              const SizedBox(height: 12),
              const Text('Start the server to allow staff members to connect and sync data.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              const Divider(height: 24),
              SwitchListTile(
                title: const Text('Auto-start Server on App Launch'),
                value: _autoStartServer,
                onChanged: _onAutoStartServerChanged,
              ),
          ],
      );
  }

  Widget _buildClientView() {
      return Column(
          children: [
              SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                      onPressed: _autoConnect,
                      icon: const Icon(Icons.radar),
                      label: const Text('AUTO SCAN & CONNECT'),
                  ),
              ),
              const SizedBox(height: 16),
              const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR MANUAL')), Expanded(child: Divider())]),
              const SizedBox(height: 16),
              Row(
                  children: [
                      Expanded(
                          flex: 2,
                          child: TextFormField(
                              controller: _clientIpController,
                              decoration: const InputDecoration(labelText: 'Server IP', border: OutlineInputBorder(), hintText: '192.168.1.X'),
                          ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 1,
                          child: TextFormField(
                              controller: _clientPortController,
                              decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
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
                        onPressed: _manualConnect,
                        icon: Icon(_isConnected ? Icons.link_off : Icons.link),
                        label: Text(_isConnected ? 'DISCONNECT' : 'CONNECT'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _isConnected ? Colors.redAccent : Colors.blueAccent,
                            foregroundColor: Colors.white,
                        ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Check Port',
                    onPressed: _checkPort,
                  ),
                  IconButton(
                    icon: const Icon(Icons.security),
                    tooltip: 'Open Port in Firewall',
                    onPressed: _openPort,
                    color: Colors.orange,
                  ),
                ],
              ),
              const Divider(height: 24),
              SwitchListTile(
                title: const Text('Auto-connect on App Launch'),
                value: _autoConnectClient,
                onChanged: _onAutoConnectClientChanged,
              ),
          ],
      );
  }
}