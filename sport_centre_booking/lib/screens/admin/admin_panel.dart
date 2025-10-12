import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../models/booking.dart';
import '../../models/user_profile.dart';
import '../../services/activity_service.dart';

class AdminPanel extends StatelessWidget {
  final ActivityService _activityService = ActivityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Quick Stats Row
            Row(
              children: [
                _StatCard(
                  title: 'Total Activities',
                  value: '24', // You'd fetch this from your service
                  icon: Icons.emoji_events,
                  color: Colors.blue,
                ),
                SizedBox(width: 12),
                _StatCard(
                  title: 'Total Bookings',
                  value: '156',
                  icon: Icons.bookmark,
                  color: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Admin Actions
            Expanded(
              child: ListView(
                children: [
                  _AdminTile(
                    icon: Icons.emoji_events,
                    title: 'Manage Activities',
                    subtitle: 'Add, edit, or remove activities',
                    onTap: () => _navigateToActivityManagement(context),
                    color: Colors.blue,
                  ),
                  
                  _AdminTile(
                    icon: Icons.bookmark,
                    title: 'View All Bookings',
                    subtitle: 'See all user bookings and analytics',
                    onTap: () => _navigateToBookingsManagement(context),
                    color: Colors.green,
                  ),
                  
                  _AdminTile(
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'Manage users and permissions',
                    onTap: () => _navigateToUserManagement(context),
                    color: Colors.orange,
                  ),
                  
                  _AdminTile(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View app usage statistics',
                    onTap: () => _navigateToAnalytics(context),
                    color: Colors.purple,
                  ),
                  
                  _AdminTile(
                    icon: Icons.settings,
                    title: 'App Configuration',
                    subtitle: 'Manage app settings and features',
                    onTap: () => _navigateToAppConfig(context),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToActivityManagement(BuildContext context) {
    // Navigate to activity management screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityManagementScreen()));
  }
  
  void _navigateToBookingsManagement(BuildContext context) {
    // Navigate to bookings management
  }
  
  void _navigateToUserManagement(BuildContext context) {
    // Navigate to user management
  }
  
  void _navigateToAnalytics(BuildContext context) {
    // Navigate to analytics
  }
  
  void _navigateToAppConfig(BuildContext context) {
    // Navigate to app configuration
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
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}