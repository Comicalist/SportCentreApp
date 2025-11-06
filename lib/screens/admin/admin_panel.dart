import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/club_service.dart';
import '../../utils/update_bookings_with_user_info.dart';
import '../../utils/sample_data_seeder.dart';
import 'club_approval_screen.dart';

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
                    title: 'Seed Swiss Sport Centre Data',
                    subtitle: 'Generate comprehensive Swiss sport centre ecosystem',
                    onTap: () => _showSeedDialog(context),
                    color: Colors.teal,
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

  /// Show comprehensive seeding dialog with options
  void _showSeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.teal),
            SizedBox(width: 8),
            Text('Swiss Sport Centre Seeder'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🇨🇭 This will create a complete Swiss sport centre ecosystem:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                const Text('• 11 users with different roles (admin, club owners, members)'),
                const Text('• 3 Swiss clubs (Zürich, Basel, Bern)'),
                const Text('• 7 realistic facilities with blocking schedules'),
                const Text('• 80+ activities over next 2 months'),
                const Text('• Realistic bookings, vouchers, and notifications'),
                const Text('• CHF pricing (15-150 range)'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Important Notes:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• This process may take 30-60 seconds'),
                      Text('• Uses your existing user accounts'),
                      Text('• Adds sample data without clearing existing data'),
                      Text('• User credentials will be displayed after completion'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _runComprehensiveSeeder(context);
            },
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
  }

  /// Run the comprehensive seeder with progress dialog and credential display
  Future<void> _runComprehensiveSeeder(BuildContext context) async {
    if (!context.mounted) return;
    
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 20),
            Text(
              '🇨🇭 Creating Swiss sport centre ecosystem...',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'This may take 30-60 seconds...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
    
    try {
      // Run the comprehensive seeder (never clearing existing data)
      final result = await ComprehensiveSeeder.seedCompleteDatabase(
        clearExisting: false,
      );
      
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        
        if (result['success'] == true) {
          _showCredentialsDialog(context, result);
        } else {
          _showErrorDialog(context, 'Seeding failed: ${result['error'] ?? 'Unknown error'}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        _showErrorDialog(context, 'Seeding failed: $e');
      }
    }
  }

  /// Show credentials dialog with copy functionality
  void _showCredentialsDialog(BuildContext context, Map<String, dynamic> result) {
    final credentials = List<Map<String, String>>.from(result['credentials'] ?? []);
    final summary = result['summary'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Seeding Complete!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Successfully Created:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('👥 ${summary['users'] ?? 0} users'),
                      Text('🏢 ${summary['clubs'] ?? 0} clubs'),
                      Text('🏟️ ${summary['facilities'] ?? 0} facilities'),
                      Text('🏃 ${summary['activities'] ?? 0} activities'),
                      Text('🎫 ${summary['vouchers'] ?? 0} vouchers'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Credentials
                const Text(
                  '🔑 User Credentials:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                ...credentials.map((cred) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cred['type'] ?? 'USER'}: ${cred['name'] ?? 'Unknown'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('📧 '),
                          Expanded(child: Text(cred['email'] ?? '')),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: cred['email'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Email copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('🔐 '),
                          Expanded(child: Text(cred['password'] ?? '')),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: cred['password'] ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Quick Start:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text('1. Use admin credentials to access admin panel'),
                      Text('2. Use club owner credentials to manage activities'),
                      Text('3. Use member credentials to book activities'),
                      Text('4. All clubs are located in Swiss cities'),
                      Text('5. Activities span next 2 months with CHF pricing'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog for seeding failures
  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Seeding Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text(
              'Please check your Firebase configuration and try again.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
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
