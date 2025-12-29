import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:flutter/material.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

class DeveloperOverviewScreen extends StatelessWidget {
  const DeveloperOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeveloperService developerService = DeveloperService();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.developerOverview)),
      body: StreamBuilder<List<UserProfile>>(
        stream: developerService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${l10n.errorLabel}: ${snapshot.error}'));
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.systemHealth,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _OverviewCard(
                      l10n.totalUsers,
                      totalUsers.toString(),
                      Icons.people_outline,
                      Colors.blue,
                    ),
                    _OverviewCard(
                      l10n.premiumAccount,
                      premiumUsers.toString(),
                      Icons.star_outline,
                      Colors.amber,
                    ),
                    _OverviewCard(
                      l10n.activeTrials,
                      trialUsers.toString(),
                      Icons.timer_outlined,
                      Colors.green,
                    ),
                    _OverviewCard(
                      l10n.estRevenue,
                      '\$$revenueEstimate',
                      Icons.payments_outlined,
                      Colors.purple,
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
