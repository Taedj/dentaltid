import 'dart:math';

import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:dentaltid/src/features/developer/data/broadcast_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DeveloperDashboardScreen extends ConsumerStatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  ConsumerState<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState
    extends ConsumerState<DeveloperDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.group), text: 'User Management'),
            Tab(icon: Icon(Icons.vpn_key), text: 'Activation Codes'),
            Tab(icon: Icon(Icons.campaign), text: 'Broadcasts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UserManagementTab(),
          ActivationCodeTab(),
          BroadcastTab(),
        ],
      ),
    );
  }
}

// --- USER MANAGEMENT TAB (With Analytics) ---

class UserManagementTab extends StatelessWidget {
  const UserManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    final DeveloperService developerService = DeveloperService();

    return StreamBuilder<List<UserProfile>>(
      stream: developerService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: SelectableText('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        // Calculation for Analytics
        final totalUsers = users.length;
        final premiumUsers = users.where((u) => u.isPremium).length;
        final trialUsers = users
            .where(
              (u) =>
                  !u.isPremium &&
                  (u.trialStartDate != null && !u.isTrialExpired),
            )
            .length;
        final revenueEstimate = premiumUsers * 9; // E.g. $9/month basic math

        return Column(
          children: [
            // ANALYTICS HEADER
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    'Total Users',
                    totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _StatCard(
                    'Premium',
                    premiumUsers.toString(),
                    Icons.star,
                    Colors.amber,
                  ),
                  _StatCard(
                    'Active Trials',
                    trialUsers.toString(),
                    Icons.timer,
                    Colors.orange,
                  ),
                  _StatCard(
                    'Est. Monthly',
                    '\$${revenueEstimate}0',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // LIST
            Expanded(
              child: ListView.builder(
                itemCount: totalUsers,
                itemBuilder: (context, index) {
                  final user = users[index];

                  // Calculate days left
                  String daysLeftInfo = 'Free/Trial';
                  Color daysLeftColor = Colors.grey;

                  if (user.isPremium) {
                    if (user.premiumExpiryDate != null) {
                      final days = user.premiumExpiryDate!
                          .difference(DateTime.now())
                          .inDays;
                      daysLeftInfo = '$days days left (Premium)';
                      daysLeftColor = days > 30 ? Colors.green : Colors.orange;
                    } else {
                      daysLeftInfo = 'Premium (Lifetime/No Expiry)';
                      daysLeftColor = Colors.green;
                    }
                  } else if (user.trialStartDate != null) {
                    final daysUsed = DateTime.now()
                        .difference(user.trialStartDate!)
                        .inDays;
                    final days = 30 - daysUsed;
                    daysLeftInfo = days > 0
                        ? '$days days left (Trial)'
                        : 'Trial Expired';
                    daysLeftColor = days > 0 ? Colors.blue : Colors.red;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: user.isPremium
                            ? Colors.amber
                            : Colors.grey,
                        child: Icon(
                          user.role == UserRole.developer
                              ? Icons.code
                              : Icons.person,
                        ),
                      ),
                      title: Text(user.dentistName ?? user.email),
                      subtitle: Text(user.phoneNumber ?? 'No Phone'),
                      trailing: Chip(
                        label: Text(
                          user.plan.toString().split('.').last.toUpperCase(),
                        ),
                        backgroundColor: _getPlanColor(user.plan),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _InfoRow('Email', user.email),
                              _InfoRow('UID', user.uid),
                              _InfoRow('Phone', user.phoneNumber ?? 'N/A'),
                              _InfoRow('Clinic', user.clinicName ?? 'N/A'),
                              const Divider(),
                              _InfoRow(
                                'Status',
                                user.status.toString().split('.').last,
                              ),
                              _InfoRow(
                                'Time Left',
                                daysLeftInfo,
                                color: daysLeftColor,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showPlanDialog(
                                      context,
                                      user,
                                      developerService,
                                    ),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Manage Plan'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPlanDialog(
    BuildContext context,
    UserProfile user,
    DeveloperService service,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Grant 1 Year Professional'),
              onTap: () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.professional,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: DateTime.now().add(const Duration(days: 365)),
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Revoke Premium'),
              onTap: () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.free,
                  status: SubscriptionStatus.active,
                  isPremium: false,
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return Colors.grey[300]!;
      case SubscriptionPlan.professional:
        return Colors.amber[200]!;
      case SubscriptionPlan.enterprise:
        return Colors.purple[200]!;
      default:
        return Colors.blue[100]!;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

// --- ACTIVATION CODE TAB ---

class ActivationCodeTab extends ConsumerStatefulWidget {
  const ActivationCodeTab({super.key});

  @override
  ConsumerState<ActivationCodeTab> createState() => _ActivationCodeTabState();
}

class _ActivationCodeTabState extends ConsumerState<ActivationCodeTab> {
  final _formKey = GlobalKey<FormState>();
  final DeveloperService _developerService = DeveloperService();
  int _selectedDurationMonths = 1;
  String? _generatedCode;
  bool _isLoading = false;

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(27, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _generateAndSaveCode() async {
    setState(() {
      _isLoading = true;
      _generatedCode = null;
    });

    try {
      final code = _generateRandomCode();
      await ref
          .read(firebaseServiceProvider)
          .createActivationCode(
            code: code,
            durationMonths: _selectedDurationMonths,
            type: 'premium_subscription',
          );

      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating code: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCode(String id) async {
    try {
      await _developerService.deleteActivationCode(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: Generator
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: _selectedDurationMonths,
                            decoration: const InputDecoration(
                              labelText: 'Duration',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('1 Month'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('3 Months'),
                              ),
                              DropdownMenuItem(
                                value: 6,
                                child: Text('6 Months'),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text('1 Year'),
                              ),
                              DropdownMenuItem(
                                value: 1200,
                                child: Text('Lifetime (100 Years)'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDurationMonths = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : _generateAndSaveCode,
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Generate Code'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_generatedCode != null) ...[
                  const Text(
                    'New Code:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: SelectableText(
                      _generatedCode!,
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        // RIGHT: List
        Expanded(
          flex: 6,
          child: StreamBuilder<List<ActivationCodeModel>>(
            stream: _developerService.getActivationCodes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final codes = snapshot.data!;

              return ListView.separated(
                itemCount: codes.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final code = codes[index];
                  final isRedeemed = code.isRedeemed;

                  return ListTile(
                    title: SelectableText(
                      code.code,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration: ${code.durationMonths} months • Created: ${DateFormat.yMMMd().format(code.createdAt)}',
                        ),
                        if (isRedeemed) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Used used: ${code.redeemedAt != null ? DateFormat.yMMMd().add_Hm().format(code.redeemedAt!) : 'Unknown'}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (code.redeemedByEmail != null)
                            Text('Email: ${code.redeemedByEmail}'),
                          if (code.redeemedByPhone != null)
                            Text('Phone: ${code.redeemedByPhone}'),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRedeemed)
                          const Chip(
                            label: Text('USED'),
                            backgroundColor: Colors.amberAccent,
                          )
                        else
                          const Chip(
                            label: Text('ACTIVE'),
                            backgroundColor: Colors.greenAccent,
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => _confirmDelete(code),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(ActivationCodeModel code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Code'),
        content: Text('Are you sure you want to delete code ${code.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteCode(code.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// --- BROADCAST TAB ---
class BroadcastTab extends ConsumerStatefulWidget {
  const BroadcastTab({super.key});

  @override
  ConsumerState<BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<BroadcastTab> {
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
        content: const Text(
          'This message will be visible to ALL users immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SEND'),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Broadcast Sent!')));
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  const Text(
                    'Compose New Broadcast',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'info',
                        child: Text('ℹ️ Info / Update'),
                      ),
                      DropdownMenuItem(
                        value: 'warning',
                        child: Text('⚠️ Warning / Alert'),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text('🛠️ Maintenance'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _sendBroadcast,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(Icons.send),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SEND TO ALL USERS'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
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
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = snapshot.data!;
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return ListTile(
                    leading: _getIcon(item.type),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () =>
                          _broadcastService.deleteBroadcast(item.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _getIcon(String type) {
    switch (type) {
      case 'warning':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'maintenance':
        return const Icon(Icons.build, color: Colors.red);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }
}
