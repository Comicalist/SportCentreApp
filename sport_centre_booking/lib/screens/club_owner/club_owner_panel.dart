import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'club_management_screen.dart';
import 'add_club_screen.dart';

class ClubOwnerPanel extends StatelessWidget {
  final ClubService _clubService = ClubService();

  ClubOwnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = authProvider.appUser?.uid;

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

            // Quick Stats Row
            FutureBuilder<Map<String, dynamic>>(
              future: _getOwnerStats(ownerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Expanded(child: _StatCard(title: 'My Clubs', value: '...', icon: Icons.sports_soccer, color: Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Pending', value: '...', icon: Icons.pending, color: Colors.orange)),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return const Row(
                    children: [
                      Expanded(child: _StatCard(title: 'My Clubs', value: '0', icon: Icons.sports_soccer, color: Colors.orange)),
                      SizedBox(width: 12),
                      Expanded(child: _StatCard(title: 'Pending', value: '0', icon: Icons.pending, color: Colors.orange)),
                    ],
                  );
                }

                final stats = snapshot.data ?? {'total': 0, 'pending': 0};
                
                return Row(
                  children: [
                    _StatCard(
                      title: 'My Clubs',
                      value: stats['total'].toString(),
                      icon: Icons.sports_soccer,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Pending Approval',
                      value: stats['pending'].toString(),
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ],
                );
              },
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
                    icon: Icons.add_business,
                    title: 'Add New Club',
                    subtitle: 'Submit a new club for approval',
                    color: Colors.green,
                    onTap: () => _navigateToAddClub(context),
                  ),
                  _OwnerTile(
                    icon: Icons.bookmark,
                    title: 'View Bookings',
                    subtitle: 'Bookings for your clubs',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: Navigate to club bookings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bookings feature coming soon!')),
                      );
                    },
                  ),
                  _OwnerTile(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View performance of your clubs',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Navigate to analytics screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Analytics feature coming soon!')),
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

  Future<Map<String, dynamic>> _getOwnerStats(String? ownerId) async {
    if (ownerId == null) return {'total': 0, 'pending': 0};

    try {
      final clubs = await _clubService.getOwnedClubs(ownerId: ownerId);
      final pendingCount = clubs.where((club) => !club.isApproved).length;
      
      return {
        'total': clubs.length,
        'pending': pendingCount,
      };
    } catch (e) {
      print('Error fetching owner stats: $e');
      return {'total': 0, 'pending': 0};
    }
  }

  void _navigateToClubManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClubManagementScreen(),
      ),
    );
  }

  void _navigateToAddClub(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddClubScreen(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _OwnerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

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