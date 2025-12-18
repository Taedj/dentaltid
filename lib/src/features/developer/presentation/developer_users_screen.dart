import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeveloperUsersScreen extends StatefulWidget {
  const DeveloperUsersScreen({super.key});

  @override
  State<DeveloperUsersScreen> createState() => _DeveloperUsersScreenState();
}

class _DeveloperUsersScreenState extends State<DeveloperUsersScreen> {
  final DeveloperService _developerService = DeveloperService();
  String _searchQuery = '';
  String _filterPlan = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('User Intelligence Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _developerService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allUsers = snapshot.data ?? [];
          
          // Filtering logic
          final filteredUsers = allUsers.where((u) {
            final matchesSearch = u.email.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                (u.dentistName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            final matchesPlan = _filterPlan == 'all' || u.plan.toString().contains(_filterPlan);
            return matchesSearch && matchesPlan;
          }).toList();

          return Column(
            children: [
              _buildSummaryHeader(allUsers),
              _buildFilterBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) => _UserAdvancedCard(
                    user: filteredUsers[index],
                    service: _developerService,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<UserProfile> users) {
    final total = users.length;
    final premium = users.where((u) => u.isPremium).length;
    final powerUsers = users.where((u) => (u.cumulativePatients + u.cumulativeAppointments) > 100).length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Users', total.toString(), Icons.group, Colors.blue),
          _buildStatItem('Premium', premium.toString(), Icons.star, Colors.amber),
          _buildStatItem('Power Users', powerUsers.toString(), Icons.bolt, Colors.purple),
          _buildStatItem('Conv. Rate', '${((premium/total)*100).toStringAsFixed(1)}%', Icons.trending_up, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButton<String>(
              value: _filterPlan,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Plans')),
                DropdownMenuItem(value: 'trial', child: Text('Trial')),
                DropdownMenuItem(value: 'professional', child: Text('Premium')),
              ],
              onChanged: (v) => setState(() => _filterPlan = v!),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAdvancedCard extends StatelessWidget {
  final UserProfile user;
  final DeveloperService service;

  const _UserAdvancedCard({required this.user, required this.service});

  @override
  Widget build(BuildContext context) {
    final totalEngagement = user.cumulativePatients + user.cumulativeAppointments + user.cumulativeInventory;
    String level = 'Ghost';
    Color levelColor = Colors.grey;
    
    if (totalEngagement > 200) { level = 'Power User'; levelColor = Colors.purple; }
    else if (totalEngagement > 20) { level = 'Active'; levelColor = Colors.green; }
    else if (totalEngagement > 0) { level = 'Beginner'; levelColor = Colors.blue; }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: levelColor.withOpacity(0.1),
          child: Icon(user.isPremium ? Icons.verified : Icons.person, color: levelColor),
        ),
        title: Row(
          children: [
            Expanded(child: Text(user.dentistName ?? 'Unknown User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            _buildBadge(level, levelColor),
          ],
        ),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildUsageSection(),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan: ${user.plan.toString().split('.').last.toUpperCase()}', 
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Joined: ${user.createdAt.toString().split(' ')[0]}', 
                             style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _showPlanDialog(context),
                      child: const Text('Manage Plan'),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resource Usage (Trial Limits)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        _buildMeter('Patients', user.cumulativePatients, 100, Colors.blue),
        _buildMeter('Appointments', user.cumulativeAppointments, 100, Colors.green),
        _buildMeter('Inventory', user.cumulativeInventory, 100, Colors.orange),
      ],
    );
  }

  Widget _buildMeter(String label, int current, int limit, Color color) {
    final double progress = (current / limit).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              Text('$current/$limit', style: TextStyle(fontSize: 11, color: progress >= 0.9 ? Colors.red : Colors.black)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progress >= 0.9 ? Colors.red : color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanDialog(BuildContext context) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Advanced Subscription Control'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  _planOption(ctx, '1 Year Professional', Icons.workspace_premium, Colors.amber, () {
                      service.updateUserPlan(user.uid, plan: SubscriptionPlan.professional, status: SubscriptionStatus.active, isPremium: true, expiryDate: DateTime.now().add(const Duration(days: 365)));
                  }),
                  _planOption(ctx, 'Lifetime Access', Icons.all_inclusive, Colors.purple, () {
                      service.updateUserPlan(user.uid, plan: SubscriptionPlan.professional, status: SubscriptionStatus.active, isPremium: true, expiryDate: DateTime.now().add(const Duration(days: 36500)));
                  }),
                  _planOption(ctx, 'Reset to Trial', Icons.refresh, Colors.blue, () {
                      service.updateUserPlan(user.uid, plan: SubscriptionPlan.trial, status: SubscriptionStatus.active, isPremium: false);
                  }),
                  _planOption(ctx, 'Revoke All (Free)', Icons.block, Colors.red, () {
                      service.updateUserPlan(user.uid, plan: SubscriptionPlan.free, status: SubscriptionStatus.active, isPremium: false);
                  }),
              ],
          ),
      ));
  }

  Widget _planOption(BuildContext ctx, String label, IconData icon, Color color, VoidCallback action) {
      return ListTile(
          leading: Icon(icon, color: color),
          title: Text(label),
          onTap: () { action(); Navigator.pop(ctx); },
      );
  }
}

