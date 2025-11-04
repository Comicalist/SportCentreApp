import 'package:flutter/material.dart';
import '../../services/club_service.dart';
import '../../utils/update_bookings_with_user_info.dart';
import 'club_approval_screen.dart';
import 'participants_management_screen.dart';

/// Central administration dashboard for sport centre management
///
/// Provides system administrators with quick access to core management functions.
/// Only accessible to users with admin role privileges.
class AdminPanel extends StatelessWidget {
  AdminPanel({super.key});
  final ClubService _clubService = ClubService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // System overview statistics
            Row(
              children: [
                const Expanded(
                  child: _StatCard(
                    title: 'Total Activities',
                    value: '24', // Static placeholder - could be made dynamic
                    icon: Icons.emoji_events,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Clubs',
                    value: '0', // Default fallback value
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    future: _clubService.getPendingClubsCount(), // Real-time count
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Administrative action menu
            Expanded(
              child: ListView(
                children: [
                  _AdminTile(
                    icon: Icons.approval,
                    title: 'Club Approvals',
                    subtitle: 'Review and approve pending clubs',
                    onTap: () => _navigateToClubApprovals(context),
                    color: Colors.orange,
                    badgeFuture: _clubService.getPendingClubsCount(), // Shows pending count
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
      MaterialPageRoute(builder: (context) => const ClubApprovalScreen()),
    );
  }

  /// Navigate to participant management system
  void _navigateToParticipants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminParticipantsScreen()),
    );
  }

  /// Show placeholder dialog for unimplemented seeding feature
  void _showSeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Activities'),
        content: const Text(
          'This feature is not yet implemented. It will generate sample activities for testing.',
        ),
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

/// Statistical overview card with optional real-time data fetching
///
/// Displays key metrics with icons and supports both static values and
/// dynamic data loading via Future for real-time statistics.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.future,
  });

  final String title; // Metric name (e.g., "Total Activities")
  final String value; // Default/fallback value
  final IconData icon; // Visual identifier
  final Color color; // Theme color for icon
  final Future<int>? future; // Optional real-time data source

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

  /// Build card content with consistent layout
  Widget _buildContent(String displayValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          displayValue,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

/// Administrative function tile with optional notification badges
///
/// Represents a specific admin function with navigation capability and
/// optional notification counts (e.g., pending approvals, alerts).
class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.badgeFuture,
  });

  final IconData icon; // Function identifier
  final String title; // Primary action name
  final String subtitle; // Description of function
  final VoidCallback onTap; // Navigation/action handler
  final Color color; // Theme color for icon
  final Future<int>? badgeFuture; // Optional notification count

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onTap,
          ),
          // Notification badge overlay for pending items
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
        ],
      ),
    );
  }
}
