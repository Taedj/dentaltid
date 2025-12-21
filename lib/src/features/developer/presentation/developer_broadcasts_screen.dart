import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/developer/data/broadcast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeveloperBroadcastsScreen extends ConsumerStatefulWidget {
  const DeveloperBroadcastsScreen({super.key});

  @override
  ConsumerState<DeveloperBroadcastsScreen> createState() => _DeveloperBroadcastsScreenState();
}

class _DeveloperBroadcastsScreenState extends ConsumerState<DeveloperBroadcastsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final BroadcastService _broadcastService = BroadcastService();
  String _selectedType = 'info';
  bool _isLoading = false;

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Safety check - confirm
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Send Broadcast?'),
            content: const Text('This message will be visible to ALL users immediately.'),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SEND')),
            ],
        )
    );
    
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
        final currentUser = ref.read(firebaseServiceProvider).getCurrentUser();
        
      await _broadcastService.sendBroadcast(
        title: _titleController.text,
        message: _messageController.text,
        type: _selectedType,
        authorId: currentUser?.uid ?? 'unknown',
      );
      
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast Sent!')));
          _titleController.clear();
          _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Broadcasts')),
        body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Compose
            Expanded(
                flex: 4,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const Text('Compose New Broadcast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                    initialValue: _selectedType,
                                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                                    items: const [
                                        DropdownMenuItem(value: 'info', child: Text('ℹ️ Info / Update')),
                                        DropdownMenuItem(value: 'warning', child: Text('⚠️ Warning / Alert')),
                                        DropdownMenuItem(value: 'maintenance', child: Text('🛠️ Maintenance')),
                                    ],
                                    onChanged: (v) => setState(() => _selectedType = v!),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder()),
                                    maxLines: 5,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton.icon(
                                        onPressed: _isLoading ? null : _sendBroadcast,
                                        icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.send),
                                        label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SEND TO ALL USERS'),
                                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
            const VerticalDivider(width: 1),
            // History
            Expanded(
                flex: 6,
                child: StreamBuilder<List<BroadcastModel>>(
                    stream: _broadcastService.getActiveBroadcasts(),
                    builder: (context, snapshot) {
                         if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                         if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                         
                         final list = snapshot.data!;
                         return ListView.builder(
                             itemCount: list.length,
                             itemBuilder: (context, index) {
                                 final item = list[index];
                                 return ListTile(
                                     leading: _getIcon(item.type),
                                     title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                     subtitle: Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                                     trailing: IconButton(
                                         icon: const Icon(Icons.delete, color: Colors.grey),
                                         onPressed: () => _broadcastService.deleteBroadcast(item.id),
                                     ),
                                 );
                             },
                         );
                    }
                ),
            ),
        ],
    ));
  }
  
  Widget _getIcon(String type) {
      switch(type) {
          case 'warning': return const Icon(Icons.warning, color: Colors.orange);
          case 'maintenance': return const Icon(Icons.build, color: Colors.red);
          default: return const Icon(Icons.info, color: Colors.blue);
      }
  }
}
