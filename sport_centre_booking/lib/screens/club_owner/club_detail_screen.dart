import 'package:flutter/material.dart';
import '../../models/club.dart';
import '../../services/club_service.dart';
import 'edit_club_screen.dart';
import '../facilities/club_facilities_screen.dart';
import 'edit_open_hours_screen.dart';


class ClubDetailScreen extends StatefulWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final ClubService _clubService = ClubService();
  late Club _currentClub;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentClub = widget.club;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClub.name),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _navigateToEdit),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Club Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Name', _currentClub.name),
            if (_currentClub.location != null &&
                _currentClub.location!.isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                'Location',
                _currentClub.location!,
              ),
            _buildInfoRow(
              Icons.circle,
              'Status',
              _currentClub.isActive ? 'Active' : 'Inactive',
              statusColor: _currentClub.isActive ? Colors.green : Colors.red,
            ),
            _buildInfoRow(
              Icons.verified,
              'Approval',
              _currentClub.isApproved ? 'Approved' : 'Pending',
              statusColor: _currentClub.isApproved
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.black,
                fontWeight: statusColor != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Manage Club',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),
            
            _buildActionTile(
              icon: Icons.home_work,
              title: 'View Facilities',
              subtitle: 'Manage club facilities and resources',
              onTap: _viewFacilities,
            ),

            const Divider(),

            _buildActionTile(
              icon: Icons.access_time,
              title: 'Edit Open Hours',
              subtitle: 'Adjust or block specific club hours',
              onTap: _editOpenHours,
            ),

            const Divider(),

            _buildActionTile(
              icon: Icons.delete,
              title: 'Delete Club',
              subtitle: 'Permanently remove this club',
              onTap: _confirmDelete,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.orange),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _navigateToEdit() async {
    final updatedClub = await Navigator.push<Club>(
      context,
      MaterialPageRoute(
        builder: (context) => EditClubScreen(club: _currentClub),
      ),
    );

    if (updatedClub != null) {
      setState(() {
        _currentClub = updatedClub;
      });
    }
  }

  void _viewFacilities() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubFacilitiesScreen(club: _currentClub),
      ),
    );
  }

  void _editOpenHours() {
    Navigator.push(
      context,
    MaterialPageRoute(
        builder: (context) => EditOpenHoursScreen(club: _currentClub),
      ),
    );
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Club'),
        content: Text(
          'Are you sure you want to delete "${_currentClub.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClub();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClub() async {
    setState(() => _isLoading = true);

    try {
      await _clubService.deleteClub(_currentClub.id);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting club: $e'),
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
