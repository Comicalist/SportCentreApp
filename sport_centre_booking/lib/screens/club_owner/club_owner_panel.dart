import 'package:flutter/material.dart';

import 'activity_management_screen.dart';
import 'club_management_screen.dart';
import 'voucher_management_screen.dart';

class ClubOwnerPanel extends StatelessWidget {
  const ClubOwnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Club Owner Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Owner Actions
            Expanded(
              child: ListView(
                children: [
                  _OwnerTile(
                    icon: Icons.sports_soccer,
                    title: 'Manage My Clubs',
                    subtitle: 'Add, edit, or view your clubs',
                    color: Colors.orange,
                    onTap: () => _navigateToClubManagement(context),
                  ),
                  _OwnerTile(
                    icon: Icons.event,
                    title: 'Manage Activities',
                    subtitle: 'Create and manage your club activities',
                    color: Colors.teal,
                    onTap: () => _navigateToActivityManagement(context),
                  ),
                  _OwnerTile(
                    icon: Icons.card_giftcard,
                    title: 'Manage Vouchers',
                    subtitle: 'Create and manage vouchers for your clubs',
                    color: Colors.green,
                    onTap: () => _navigateToVoucherManagement(context),
                  ),
                  _OwnerTile(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View performance of your clubs',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigate to analytics screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Analytics feature coming soon!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToClubManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClubManagementScreen()),
    );
  }

  void _navigateToActivityManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityManagementScreen()),
    );
  }

  void _navigateToVoucherManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoucherManagementScreen()),
    );
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
