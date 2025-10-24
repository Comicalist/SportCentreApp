import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../models/club.dart';
import '../../services/activity_service.dart';
import '../../services/club_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_activity_screen.dart';
import 'edit_activity_screen.dart';

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({super.key});

  @override
  State<ActivityManagementScreen> createState() => _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  final _clubService = ClubService();
  List<Club> _ownedClubs = [];
  Club? _selectedClub;
  bool _isLoadingClubs = true;

  @override
  void initState() {
    super.initState();
    _loadOwnedClubs();
  }

  Future<void> _loadOwnedClubs() async {
    setState(() => _isLoadingClubs = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final clubs = await _clubService.getApprovedOwnedClubs(ownerId: user.uid);

      setState(() {
        _ownedClubs = clubs;
        _isLoadingClubs = false;
        if (clubs.isNotEmpty) {
          _selectedClub = clubs.first;
        }
      });
    } catch (e) {
      setState(() => _isLoadingClubs = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clubs: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await ActivityService.deleteActivity(
        activityId: activity.id,
        clubId: activity.clubId,
        currentUserId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddActivityScreen()),
              );
            },
            tooltip: 'Create Activity',
          ),
        ],
      ),
      body: _isLoadingClubs
          ? const Center(child: CircularProgressIndicator())
          : _ownedClubs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.business, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No Approved Clubs',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You need at least one approved club to manage activities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Club filter
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, color: Colors.teal),
                          const SizedBox(width: 12),
                          const Text(
                            'Filter by Club:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<Club>(
                              value: _selectedClub,
                              isExpanded: true,
                              items: _ownedClubs.map((club) {
                                return DropdownMenuItem(
                                  value: club,
                                  child: Text(club.name),
                                );
                              }).toList(),
                              onChanged: (club) {
                                setState(() => _selectedClub = club);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Activities list
                    Expanded(
                      child: _selectedClub == null
                          ? const Center(child: Text('Select a club'))
                          : StreamBuilder<List<Activity>>(
                              stream: ActivityService.getActivitiesByClub(_selectedClub!.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error, size: 64, color: Colors.red),
                                        const SizedBox(height: 16),
                                        Text('Error: ${snapshot.error}'),
                                      ],
                                    ),
                                  );
                                }

                                final activities = snapshot.data ?? [];

                                if (activities.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No activities yet',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Create your first activity for ${_selectedClub!.name}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const AddActivityScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.add),
                                          label: const Text('Create Activity'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Sort activities by date
                                activities.sort((a, b) => a.date.compareTo(b.date));

                                return ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: activities.length,
                                  itemBuilder: (context, index) {
                                    final activity = activities[index];
                                    return _ActivityCard(
                                      activity: activity,
                                      onDelete: () => _deleteActivity(activity),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _ownedClubs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddActivityScreen()),
                );
              },
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add),
              label: const Text('Create Activity'),
            )
          : null,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onDelete;
  final VoidCallback? onEdit; // Add this parameter

  const _ActivityCard({
    required this.activity,
    required this.onDelete,
    this.onEdit, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y');
    final isPast = activity.isPast;
    final isFull = activity.isFull;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header - NO 3-dots menu here anymore
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  activity.displayImageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.teal,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getCategoryColor(activity.category).withOpacity(0.7),
                            _getCategoryColor(activity.category).withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getCategoryIcon(activity.category),
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image not available',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Category badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(activity.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activity.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Past activity badge
              if (isPast)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PAST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Activity details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity name with 3-dots menu - MOVED HERE like facility card
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        switch (value) {
                          case 'edit':
                            _editActivity(context);
                            break;
                          case 'delete':
                            _confirmDelete(context);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        // Edit option (only if not past activity)
                        if (!isPast)
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        
                        // Delete option
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date and time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(activity.date),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.time} - ${activity.endTimeFormatted}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${activity.facilityName} @ ${activity.clubName}',
                        style: TextStyle(color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Capacity info
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.bookedCount}/${activity.capacity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.red.shade600 : Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFull ? 'Full' : 'spots',
                      style: TextStyle(
                        color: isFull ? Colors.red.shade600 : Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pricing info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '€${activity.guestPrice.toStringAsFixed(0)} (Guest)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '€${activity.memberPrice.toStringAsFixed(0)} (Member)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Points
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${activity.pointsReward} points',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit activity method
  void _editActivity(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(activity: activity),
      ),
    );
    
    // If edit was successful, refresh the parent list
    if (result == true && context.mounted) {
      if (onEdit != null) {
        onEdit!(); // Call parent refresh callback
      }
    }
  }

  // Confirm delete method
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${activity.name}"?'),
              const SizedBox(height: 8),
              if (activity.bookedCount > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This activity has ${activity.bookedCount} booking(s). Deleting will cancel all bookings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Helper method for category colors
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Wellness':
        return Colors.teal;
      case 'Fitness':
        return Colors.orange;
      case 'Kids':
        return Colors.purple;
      case 'Workshops':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Helper method for category icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Wellness':
        return Icons.spa;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Kids':
        return Icons.child_care;
      case 'Workshops':
        return Icons.school;
      default:
        return Icons.event;
    }
  }
}
