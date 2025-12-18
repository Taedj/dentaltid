import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/admin/data/admin_service.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Console'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: adminService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(user.dentistName ?? user.email),
                  subtitle: Text('${user.email} • ${user.role.toString().split('.').last}'),
                  trailing: Chip(
                    label: Text(user.plan.toString().split('.').last),
                    backgroundColor: user.isPremium ? Colors.amber : Colors.grey[200],
                  ),
                  onTap: () {
                    _showUserActions(context, user, adminService);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUserActions(BuildContext context, UserProfile user, AdminService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Grant Professional Plan'),
                onTap: () {
                  service.updateUserPlan(
                    user.uid,
                    plan: SubscriptionPlan.professional,
                    status: SubscriptionStatus.active,
                    isPremium: true,
                    expiryDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan updated to Professional')),
                  );
                },
              ),
               ListTile(
                leading: const Icon(Icons.remove_circle),
                title: const Text('Revoke Premium'),
                onTap: () {
                  service.updateUserPlan(
                    user.uid,
                    plan: SubscriptionPlan.free,
                    status: SubscriptionStatus.active,
                    isPremium: false,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Premium revoked')),
                  );
                },
              ),
              // Add more actions like "View as User" or "Ban" here
            ],
          ),
        );
      },
    );
  }
}
