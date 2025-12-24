import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:flutter/material.dart';

class DeveloperOverviewScreen extends StatelessWidget {
  const DeveloperOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeveloperService developerService = DeveloperService();

    return Scaffold(
      appBar: AppBar(title: const Text('Developer Overview')),
      body: StreamBuilder<List<UserProfile>>(
        stream: developerService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          final totalUsers = users.length;
          final premiumUsers = users.where((u) => u.isPremium).length;
          final trialUsers = users
              .where(
                (u) =>
                    !u.isPremium &&
                    (u.trialStartDate != null && !u.isTrialExpired),
              )
              .length;
          final revenueEstimate = premiumUsers * 9;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Health',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _OverviewCard(
                      'Total Users',
                      totalUsers.toString(),
                      Icons.group,
                      Colors.blue,
                    ),
                    _OverviewCard(
                      'Premium',
                      premiumUsers.toString(),
                      Icons.star,
                      Colors.amber,
                    ),
                    _OverviewCard(
                      'Active Trials',
                      trialUsers.toString(),
                      Icons.timer,
                      Colors.orange,
                    ),
                    _OverviewCard(
                      'Est. Revenue',
                      '\$${revenueEstimate}0',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ],
                ),
                // Add more overview widgets here later (e.g., recent logs)
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _OverviewCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
