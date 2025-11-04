import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../utils/update_bookings_with_user_info.dart';
import 'club_approval_screen.dart';
import 'participants_management_screen.dart';

class AdminPanel extends StatelessWidget {
  final ClubService _clubService = ClubService();

  AdminPanel({super.key});

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
                Expanded(
                  child: _StatCard(
                    title: 'Total Activities',
                    value: '24', // You'd fetch this from your service
                    icon: Icons.emoji_events,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Clubs',
                    value: '0', // We'll make this dynamic
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    future: _clubService.getPendingClubsCount(), // Add future for real data
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Admin Actions
            Expanded(
              child: ListView(
                children: [
                  _AdminTile(
                    icon: Icons.approval,
                    title: 'Club Approvals',
                    subtitle: 'Review and approve pending clubs',
                    onTap: () => _navigateToClubApprovals(context),
                    color: Colors.orange,
                    badgeFuture: _clubService.getPendingClubsCount(),
                  ),
                  
                  _AdminTile(
                    icon: Icons.add_circle_outline,
                    title: 'Seed Activities',
                    subtitle: 'Generate sample activities for testing',
                    onTap: () => _showSeedDialog(context),
                    color: Colors.teal,
                  ),
                  
                  _AdminTile(
                    icon: Icons.people,
                    title: 'Event Participants',
                    subtitle: 'View, edit, and manage all participants',
                    onTap: () => _navigateToParticipants(context),
                    color: Colors.green,
                  ),
                  
                  _AdminTile(
                    icon: Icons.sync,
                    title: 'Update Booking User Info',
                    subtitle: 'One-time: Add user names to existing bookings',
                    onTap: () => _runUpdateBookingsScript(context),
                    color: Colors.purple,
                  ),
                  
                  // Add more admin tiles as needed
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runUpdateBookingsScript(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Existing Bookings?'),
        content: const Text(
          'This will update all existing bookings to include user names and emails.\n\n'
          'This is a one-time operation and may take a few moments.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Updating bookings...'),
            ],
          ),
        ),
      );
      
      try {
        await UpdateBookingsWithUserInfo.updateAllBookings();
        
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Bookings updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _navigateToClubApprovals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClubApprovalScreen(),
      ),
    );
  }
  
  void _navigateToParticipants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminParticipantsScreen(),
      ),
    );
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
  
  void _showSeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Activities'),
        content: const Text('This feature is not yet implemented. It will generate sample activities for testing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Future<int>? future; // Add optional future for dynamic data

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.future,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: future != null 
            ? FutureBuilder<int>(
                future: future,
                builder: (context, snapshot) {
                  final dynamicValue = snapshot.data?.toString() ?? value;
                  return _buildContent(dynamicValue);
                },
              )
            : _buildContent(value),
      ),
    );
  }

  Widget _buildContent(String displayValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 8),
        Text(displayValue, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Future<int>? badgeFuture; // Add badge for notification counts

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.badgeFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(subtitle),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onTap,
          ),
          if (badgeFuture != null)
            Positioned(
              top: 8,
              right: 8,
              child: FutureBuilder<int>(
                future: badgeFuture,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  if (count > 0) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }
}