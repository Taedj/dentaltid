import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        title: Text(
          'User Intelligence Hub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _developerService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snapshot.data ?? [];

          // Filtering logic
          final filteredUsers = allUsers.where((u) {
            final matchesSearch =
                u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (u.dentistName?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);
            final matchesPlan =
                _filterPlan == 'all' || u.plan.toString().contains(_filterPlan);
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
    final powerUsers = users
        .where((u) => (u.cumulativePatients + u.cumulativeAppointments) > 100)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Users',
            total.toString(),
            Icons.group,
            Colors.blue,
          ),
          _buildStatItem(
            'Premium',
            premium.toString(),
            Icons.star,
            Colors.amber,
          ),
          _buildStatItem(
            'Power Users',
            powerUsers.toString(),
            Icons.bolt,
            Colors.purple,
          ),
          _buildStatItem(
            'Conv. Rate',
            '${((premium / total) * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
        ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
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
    // contrast colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1C1E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF42474E);

    final totalEngagement =
        user.cumulativePatients +
        user.cumulativeAppointments +
        user.cumulativeInventory;
    String engagementLevel = 'Ghost';
    Color levelColor = Colors.grey;

    if (totalEngagement > 200) {
      engagementLevel = 'Power User';
      levelColor = Colors.purple;
    } else if (totalEngagement > 20) {
      engagementLevel = 'Active';
      levelColor = Colors.green;
    } else if (totalEngagement > 0) {
      engagementLevel = 'Beginner';
      levelColor = Colors.blue;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: levelColor.withValues(alpha: 0.1),
          radius: 24,
          child: Icon(
            user.isPremium ? Icons.verified : Icons.person_outline,
            color: levelColor,
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    user.dentistName?.isNotEmpty == true
                        ? user.dentistName!
                        : 'No Name',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildPlanChip(user.plan),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: subTextColor,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: user.uid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('UID copied to clipboard')),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  user.uid,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 12, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.02),
              border: Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildDataBadge('Level', engagementLevel, levelColor),
                    const SizedBox(width: 12),
                    _buildDataBadge(
                      'Joined',
                      user.createdAt.toString().split(' ')[0],
                      Colors.blueGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildUsageSection(textColor),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Copy User Email
                        Clipboard.setData(ClipboardData(text: user.email));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied')),
                        );
                      },
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text('Copy Email'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showPlanDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getPlanColor(user.plan),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Manage Access'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.enterprise:
        return Colors.purpleAccent;
      case SubscriptionPlan.professional:
        return Colors.amber;
      case SubscriptionPlan.trial:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPlanChip(SubscriptionPlan plan) {
    final color = _getPlanColor(plan);
    String label;
    switch (plan) {
      case SubscriptionPlan.enterprise:
        label = 'CROWN';
        break;
      case SubscriptionPlan.professional:
        label = 'PREMIUM';
        break;
      case SubscriptionPlan.trial:
        label = 'TRIAL';
        break;
      default:
        label = 'FREE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSection(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resource Usage',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSimpleMeter(
                'Patients',
                user.cumulativePatients,
                100,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleMeter(
                'Appts',
                user.cumulativeAppointments,
                100,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSimpleMeter(
                'Items',
                user.cumulativeInventory,
                100,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSimpleMeter(String label, int current, int limit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              '$current',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (current / limit).clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  void _showPlanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Advanced Subscription Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _planOption(
              ctx,
              '1 Month Premium',
              Icons.calendar_view_month,
              Colors.amberAccent,
              () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.professional,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: DateTime.now().add(const Duration(days: 30)),
                );
              },
            ),
            _planOption(
              ctx,
              '1 Year Premium',
              Icons.workspace_premium,
              Colors.amber,
              () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.professional,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: DateTime.now().add(const Duration(days: 365)),
                );
              },
            ),
            _planOption(
              ctx,
              'Lifetime Premium',
              Icons.all_inclusive,
              Colors.deepOrange,
              () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.professional,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: null,
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'CROWN TIER',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _planOption(
              ctx,
              '1 Month CROWN',
              Icons.diamond_outlined,
              Colors.cyan,
              () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.enterprise,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: DateTime.now().add(const Duration(days: 30)),
                );
              },
            ),
            _planOption(ctx, '1 Year CROWN', Icons.diamond, Colors.blue, () {
              service.updateUserPlan(
                user.uid,
                plan: SubscriptionPlan.enterprise,
                status: SubscriptionStatus.active,
                isPremium: true,
                expiryDate: DateTime.now().add(const Duration(days: 365)),
              );
            }),
            _planOption(
              ctx,
              'Lifetime CROWN',
              Icons.stars,
              Colors.purpleAccent,
              () {
                service.updateUserPlan(
                  user.uid,
                  plan: SubscriptionPlan.enterprise,
                  status: SubscriptionStatus.active,
                  isPremium: true,
                  expiryDate: null,
                );
              },
            ),
            _planOption(ctx, 'Reset to Trial', Icons.refresh, Colors.blue, () {
              service.updateUserPlan(
                user.uid,
                plan: SubscriptionPlan.trial,
                status: SubscriptionStatus.active,
                isPremium: false,
              );
            }),
            _planOption(ctx, 'Revoke All (Free)', Icons.block, Colors.red, () {
              service.updateUserPlan(
                user.uid,
                plan: SubscriptionPlan.free,
                status: SubscriptionStatus.active,
                isPremium: false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _planOption(
    BuildContext ctx,
    String label,
    IconData icon,
    Color color,
    VoidCallback action,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: () {
        action();
        Navigator.pop(ctx);
      },
    );
  }
}
