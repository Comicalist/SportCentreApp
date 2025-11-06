import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';

/// Administrative workflow for reviewing and approving new club registrations
///
/// Allows system administrators to review pending club applications, view
/// submission details, and approve or reject clubs. Approved clubs can then
/// create activities and manage their facilities within the platform.
class ClubApprovalScreen extends StatefulWidget {
  const ClubApprovalScreen({super.key});

  @override
  State<ClubApprovalScreen> createState() => _ClubApprovalScreenState();
}

class _ClubApprovalScreenState extends State<ClubApprovalScreen> {
  final ClubService _clubService = ClubService();
  late Future<List<Club>> _pendingClubsFuture;
  bool _isLoading = false; // Track individual approval/rejection operations

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  /// Reload pending clubs list from server
  void _refreshData() {
    setState(() {
      _pendingClubsFuture = _clubService.getPendingClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Approvals'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Club>>(
              future: _pendingClubsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state with retry option
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading pending clubs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final pendingClubs = snapshot.data ?? [];

                // Empty state - all clubs processed
                if (pendingClubs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'No pending club approvals',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All clubs have been reviewed',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Display pending clubs requiring admin review
                return ListView.builder(
                  itemCount: pendingClubs.length,
                  itemBuilder: (context, index) {
                    final club = pendingClubs[index];
                    return _buildClubCard(club);
                  },
                );
              },
            ),
    );
  }

  /// Build club application card with review details and action buttons
  Widget _buildClubCard(Club club) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club name with pending status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Club application details
            _buildInfoRow(
              Icons.location_on,
              'Location',
              club.location ?? 'Not specified',
            ),
            _buildInfoRow(Icons.person, 'Owner ID', club.ownerId),
            _buildInfoRow(
              Icons.calendar_today,
              'Submitted',
              _formatDate(club.createdAt),
            ),
            const SizedBox(height: 16),

            // Admin decision buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectDialog(club),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _approveClub(club.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build information row with icon, label, and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// Format datetime for display (DD/MM/YYYY at HH:MM)
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Approve club application and enable club functionality
  Future<void> _approveClub(String clubId) async {
    setState(() => _isLoading = true);

    try {
      await _clubService.approveClub(clubId);
      _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Club approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving club: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show confirmation dialog before rejecting club application
  void _showRejectDialog(Club club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Club'),
        content: Text(
          'Are you sure you want to reject "${club.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectClub(club.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  /// Reject club application and remove from pending list
  Future<void> _rejectClub(String clubId) async {
    setState(() => _isLoading = true);

    try {
      await _clubService.rejectClub(clubId);
      _refreshData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Club rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting club: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
